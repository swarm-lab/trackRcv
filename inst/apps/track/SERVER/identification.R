# UI
shiny::observeEvent(refresh_display(), {
  if (toggled_tabs$toggled[5]) {
    if (toggled_tabs$toggled[6] == FALSE) {
      .toggleTabs(6:7, "ON")
      toggled_tabs$toggled[6] <<- TRUE
    }
  } else {
    .toggleTabs(6:7, "OFF")
    toggled_tabs$toggled[6] <<- FALSE
  }

  if (
    is_image(the_image) &
      input$blob_width_x == 0 &
      input$blob_height_x == 0 &
      input$blob_area_x == 0
  ) {
    shiny::updateNumericInput(
      session,
      "blob_width_x",
      value = round(n_row(the_image) / 2),
      max = n_row(the_image)
    )
    shiny::updateNumericInput(
      session,
      "blob_height_x",
      value = round(n_col(the_image) / 2),
      max = n_col(the_image)
    )
    shiny::updateNumericInput(
      session,
      "blob_area_x",
      value = 1,
      max = n_row(the_image) * n_col(the_image)
    )
  }
})


# Display
shiny::observeEvent(input$id_controls, {
  if (input$main == "5") {
    refresh_display(refresh_display() + 1)
  }
})

shiny::observeEvent(input$blob_width_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$blob_height_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$blob_area_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$blob_density_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(refresh_display(), {
  if (input$main == "5") {
    to_display <<- the_image$copy()
    sc <- max(c(n_row(to_display), n_col(to_display)) / 720)

    background <- the_background$copy()
    if (input$dark_button_x == "Darker") {
      background <- cv2$bitwise_not(background)
    }

    mask <- cv2$compare(the_mask, 0, 1L)
    mask <- cv2$divide(mask, 255)

    frame <- the_image$copy()

    if (input$dark_button_x == "Darker") {
      frame <- cv2$bitwise_not(frame)
    }

    if (input$dark_button_x == "A bit of both") {
      frame <- cv2$absdiff(frame, background)
    } else {
      frame <- cv2$subtract(frame, background)
    }

    if (input$smooth_x > 0) {
      k_size <- ceiling((input$smooth_x - 0.35) / 0.5)
      k_size <- as.integer(k_size + ((k_size %% 2) == 0))
      frame <- cv2$GaussianBlur(frame, c(k_size, k_size), input$smooth_x)
    }

    frame <- cv2$multiply(frame, mask)
    gray <- cv2$cvtColor(frame, cv2$COLOR_BGR2GRAY)
    bw <- cv2$compare(gray, input$threshold_x, 2L)

    cc <- cv2$connectedComponentsWithStats(bw)
    nz <- reticulate::py_to_r(cv2$findNonZero(cc[1]))
    labs <- reticulate::py_to_r(cc[1][cc[1]$nonzero()])

    dt <- data.table::data.table(
      label = labs,
      x = nz[,, 1],
      y = nz[,, 2]
    )

    centers <- dt[, .(x = mean(x), y = mean(y)), by = .(label)]

    d <- Rfast::dista(dt[, 2:3], centers[, 2:3])
    dt[, k := Rfast::rowMins(d)]
    gr <- unique(dt[, .(label, k)])
    data.table::setorder(gr, label)
    gr[, new_id := label]

    for (j in seq_len(nrow(gr))) {
      friends <- gr$new_id[gr$k == gr$k[j]]
      gr$new_id[gr$new_id %in% friends] <- gr$new_id[j]
    }

    uid <- unique(gr$new_id)
    dt_mat <- as.matrix(dt)
    gr <- as.matrix(gr)

    shape <- c()

    for (j in seq_len(length(uid))) {
      ix <- gr[, 3] == uid[j]
      ugr <- unique(gr[ix, 2])
      pos <- dt_mat[dt_mat[, 1] %in% gr[ix, 1], 2:3]
      pos <- pos + runif(nrow(pos) * 2, -1, 1)

      cl <- kbox(
        pos,
        centers[ugr, 2:3, drop = FALSE],
        iter.max = 1000,
        split = TRUE,
        split.width = if (is.na(input$blob_width_x)) Inf else
          input$blob_width_x,
        split.height = if (is.na(input$blob_height_x)) Inf else
          input$blob_height_x,
        split.density = if (is.na(input$blob_density_x)) 0 else
          input$blob_density_x,
        min.size = if (is.na(input$blob_area_x)) 1 else input$blob_area_x
      )
      shape <- rbind(shape, cl)
    }

    if (length(shape) > 0) {
      void <- data.table::as.data.table(cbind(id = 1:nrow(shape), shape))[,
        .drawBox(
          to_display,
          .SD$x,
          .SD$y,
          .SD$width,
          .SD$height,
          .SD$angle,
          .shades[, (.BY$id %% ncol(.shades)) + 1],
          c(255, 255, 255),
          max(1, round(sc)),
          max(1, round(sc) + 1)
        ),
        by = .(id)
      ]
    }

    x <- 0.025 * n_col(to_display)
    y <- (1 - 0.025) * n_row(to_display)

    .drawPolyLine(
      to_display,
      rbind(c(x, y - 50), c(x, y), c(x + 50, y)),
      FALSE,
      c(255L, 255L, 255),
      c(0, 0, 0),
      max(1, round(sc)),
      max(1, round(sc) + 1)
    )

    .drawText(
      to_display,
      "50 px",
      x + 6 * sc,
      y - 6 * sc,
      as.integer(max(0.5, round(0.5 * sc))),
      c(255L, 255L, 255L),
      c(0, 0, 0),
      max(1, round(sc)),
      max(1, round(sc) + 1)
    )

    print_display(print_display() + 1)
  }
})


# Compute object statistics
shiny::observeEvent(input$auto_params, {
  if (
    is_video_capture(the_video) &
      is_image(the_background) &
      is_image(the_mask)
  ) {
    shinyjs::showElement("curtain")
    shiny::showNotification(
      "Detecting objects.",
      id = "detecting",
      duration = NULL
    )

    tot_summ <- NULL

    pb <- shiny::Progress$new()
    pb$set(message = "Computing: ", value = 0, detail = "0%")
    n <- input$n_ID_frames_x
    old_check <- 0
    old_frame <- 1
    old_time <- Sys.time()

    background <- the_background$copy()
    if (input$dark_button_x == "Darker") {
      background <- cv2$bitwise_not(background)
    }

    mask <- cv2$compare(the_mask, 0, 1L)
    mask <- cv2$divide(mask, 255)

    frame_pos <- round(seq.int(
      input$video_controls_x[1],
      input$video_controls_x[3],
      length.out = input$n_ID_frames_x
    ))

    for (i in seq_along(frame_pos)) {
      the_video$set(cv2$CAP_PROP_POS_FRAMES, frame_pos[i] - 1)
      frame <- the_video$read()[1]

      if (input$dark_button_x == "Darker") {
        frame <- cv2$bitwise_not(frame)
      }

      if (input$dark_button_x == "A bit of both") {
        frame <- cv2$absdiff(frame, background)
      } else {
        frame <- cv2$subtract(frame, background)
      }

      if (input$smooth_x > 0) {
        k_size <- ceiling((input$smooth_x - 0.35) / 0.5)
        k_size <- as.integer(k_size + ((k_size %% 2) == 0))
        frame <- cv2$GaussianBlur(frame, c(k_size, k_size), input$smooth_x)
      }

      frame <- cv2$multiply(frame, mask)
      gray <- cv2$cvtColor(frame, cv2$COLOR_BGR2GRAY)
      bw <- cv2$compare(gray, input$threshold_x, 2L)

      cc <- cv2$connectedComponentsWithStats(bw)
      nz <- reticulate::py_to_r(cv2$findNonZero(cc[1]))
      labs <- reticulate::py_to_r(cc[1][cc[1]$nonzero()])

      dt <- data.table::data.table(
        label = labs,
        x = as.numeric(nz[,, 1]),
        y = as.numeric(nz[,, 2])
      )

      dt_summ <- dt[,
        data.table::as.data.table(kbox(cbind(x, y) + runif(length(x) * 2, -1, 1))),
        by = .(label)
      ]

      if (nrow(dt_summ) > 0) {
        dt_summ[, area := (width / 2) * (height / 2) * pi]
        dt_summ[, density := n / area]
        tot_summ <- data.table::rbindlist(list(tot_summ, dt_summ))
      }

      new_check <- floor(100 * i / n)
      if (new_check > (old_check + 5)) {
        new_time <- Sys.time()
        fps <- (i - old_frame + 1) /
          as.numeric(difftime(new_time, old_time, units = "secs"))
        old_check <- new_check
        old_frame <- i
        old_time <- new_time
        pb$set(
          value = new_check / 100,
          detail = paste0(
            new_check,
            "% - ",
            round(fps, digits = 2),
            "fps"
          )
        )
      }
    }

    tot_summ[,
      outlier := mvoutlier::pcout(
        cbind(scale(width), scale(height), scale(density))
      )$wfinal01 ==
        0
    ]

    pb$close()

    shiny::updateNumericInput(
      session,
      "blob_width_x",
      value = round(1.05 * max(tot_summ[outlier == FALSE, width]))
    )
    shiny::updateNumericInput(
      session,
      "blob_height_x",
      value = round(1.05 * max(tot_summ[outlier == FALSE, height]))
    )
    shiny::updateNumericInput(
      session,
      "blob_area_x",
      value = round(0.95 * min(tot_summ[outlier == FALSE, n]))
    )
    shiny::updateNumericInput(
      session,
      "blob_density_x",
      value = round(0.95 * min(tot_summ[outlier == FALSE, density]), 3)
    )

    shiny::removeNotification(id = "detecting")
    shinyjs::hideElement("curtain")
  }
})
