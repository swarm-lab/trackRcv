# Global and reactive variables
memory <- NULL
mt <- NULL
n <- NULL
sc <- NULL
background <- NULL
mask <- NULL
pb <- NULL
old_check <- NULL
old_frame <- NULL
old_time <- NULL
centers <- NULL
frame <- NULL
gray <- NULL
bw <- NULL
cc <- NULL
k_size <- NULL
dilate_kernel <- NULL

tracks_path <- shiny::reactiveVal()
loop <- shiny::reactiveVal(0)
loop_debounced <- shiny::debounce(loop, 1)


# Display
shiny::observeEvent(refresh_display(), {
  if (input$main == "7") {
    if (loop() == 0) {
      to_display <<- black_screen$copy()
    }

    print_display(print_display() + 1)
  }
})


# Tracking loop
shinyFiles::shinyFileSave(
  input,
  "track_button",
  roots = volumes,
  session = session,
  defaultRoot = default_root(),
  defaultPath = default_path()
)

shiny::observeEvent(input$track_button, {
  path <- shinyFiles::parseSavePath(volumes, input$track_button)
  tracks_path(path$datapath)
})

shiny::observeEvent(tracks_path(), {
  if (
    is_video_capture(the_video) &
      is_image(the_background) &
      is_image(the_mask) &
      length(tracks_path()) > 0
  ) {
    shinyjs::showElement("curtain")
    shiny::showNotification(
      "Tracking in progress. Press Esc to cancel.",
      id = "tracking",
      duration = NULL
    )

    memory <<- data.table::data.table(
      x = double(),
      y = double(),
      n = double(),
      frame = double(),
      id = integer(),
      track = integer(),
      width = double(),
      height = double(),
      angle = double()
    )
    mt <<- 0
    n <<- frame_position$frame_range()[2] - frame_position$frame_range()[1] + 1
    sc <<- max(c(n_row(to_display), n_col(to_display)) / 720)

    background <<- the_background$copy()
    if (input$dark_button_x == "Darker") {
      background <<- cv2$bitwise_not(background)
    }

    mask <<- cv2$compare(the_mask, 0, 1L)
    mask <<- cv2$divide(mask, 255)

    pb <<- shiny::Progress$new()
    pb$set(message = "Computing: ", value = 0, detail = "0%")
    old_check <<- 0
    old_frame <<- 1
    old_time <<- Sys.time()

    centers <<- NULL

    if (input$smooth_x > 0) {
      k_size <<- ceiling((input$smooth_x - 0.35) / 0.5)
      k_size <<- as.integer(k_size + ((k_size %% 2) == 0))
    }

    # Round structuring element used to consolidate raw connected
    # components separated by less than the calibrated single-object
    # width (e.g. a narrow-neck disconnect) -- independent of any
    # previous-frame position. Built once per tracking run since
    # blob_width_x is fixed for its duration.
    dilate_radius <- as.integer(ceiling(input$blob_width_x / 2))
    dilate_kernel <<- cv2$getStructuringElement(
      cv2$MORPH_ELLIPSE,
      c(2L * dilate_radius + 1L, 2L * dilate_radius + 1L)
    )

    the_bulk_video$set(
      cv2$CAP_PROP_POS_FRAMES,
      frame_position$frame_range()[1] - 1
    )

    loop(1)
  }
})

shiny::observeEvent(loop_debounced(), {
  if (loop() > 0) {
    if (loop() <= n) {
      frame <<- the_bulk_video$read()[1]

      if (input$preview_tracks_x) {
        to_display <<- frame$copy()
      }

      if (input$dark_button_x == "Darker") {
        frame <<- cv2$bitwise_not(frame)
      }

      if (input$dark_button_x == "A bit of both") {
        frame <<- cv2$absdiff(frame, background)
      } else {
        frame <<- cv2$subtract(frame, background)
      }

      if (input$smooth_x > 0) {
        frame <<- cv2$GaussianBlur(frame, c(k_size, k_size), input$smooth_x)
      }

      frame <<- cv2$multiply(frame, mask)
      gray <<- cv2$cvtColor(frame, cv2$COLOR_BGR2GRAY)
      bw <<- cv2$compare(gray, input$threshold_x, 2L)

      # Consolidate raw connected components that are close enough, in
      # pixel space, to plausibly be one fragmented object (e.g. a narrow
      # neck disconnect) -- never based on any previous-frame position.
      bw_dilated <- cv2$dilate(bw, dilate_kernel)
      cc <<- cv2$connectedComponentsWithStats(bw_dilated)

      # Real (undilated) foreground pixels only; each is looked up in the
      # dilated labeling to find its consolidated group.
      nz <- reticulate::py_to_r(cv2$findNonZero(bw))
      group <- reticulate::py_to_r(
        cc[1][reticulate::tuple(np$int32(nz[, 2]), np$int32(nz[, 1]))]
      )
      w <- reticulate::py_to_r(
        gray[reticulate::tuple(np$int32(nz[, 2]), np$int32(nz[, 1]))]
      ) -
        input$threshold_x

      dt <- data.table::data.table(
        group = group,
        x = as.numeric(nz[, 1]),
        y = as.numeric(nz[, 2]),
        w = w
      )

      dt_mat <- as.matrix(dt)
      uid <- unique(dt$group)

      # Each previous-frame position seeds the group whose nearest real
      # pixel is closest to it, if within max_dist_x; a position seeds at
      # most one group, a group may receive zero, one, or several seeds.
      seed_group <- rep(NA_real_, if (is.null(centers)) 0L else nrow(centers))
      if (!is.null(centers) && nrow(centers) > 0 && nrow(dt_mat) > 0) {
        d <- Rfast::dista(centers, dt_mat[, 2:3, drop = FALSE])
        nearest_ix <- Rfast::rowMins(d)
        nearest_dist <- Rfast::rowMins(d, value = TRUE)
        in_range <- nearest_dist <= input$max_dist_x
        seed_group[in_range] <- dt_mat[nearest_ix[in_range], 1]
      }

      frame_number <- reticulate::py_to_r(the_bulk_video$get(
        cv2$CAP_PROP_POS_FRAMES
      ))

      max_area <- pi * (input$blob_width_x / 2) * (input$blob_height_x / 2)

      shape <- c()

      for (j in seq_len(length(uid))) {
        ix <- dt_mat[, 1] == uid[j]
        pos <- dt_mat[ix, 2:4, drop = FALSE]

        seed_ix <- which(!is.na(seed_group) & seed_group == uid[j])

        if (length(seed_ix) == 0) {
          cl <- kbox(
            pos,
            max(1, ceiling(nrow(pos) / max_area)),
            iter.max = 1000,
            split = TRUE,
            split.width = input$blob_width_x,
            split.height = input$blob_height_x,
            split.density = input$blob_density_x,
            min.size = input$blob_area_x,
            seed = frame_number
          )
        } else {
          cl <- kbox(
            pos,
            centers[seed_ix, , drop = FALSE],
            iter.max = 1000,
            split = TRUE,
            split.width = input$blob_width_x,
            split.height = input$blob_height_x,
            split.density = input$blob_density_x,
            min.size = input$blob_area_x,
            seed = frame_number
          )
        }

        shape <- rbind(shape, cl)
      }

      centers <<- shape[, 1:2, drop = FALSE]

      if (!is.null(shape)) {
        blobs <- data.table::data.table(
          x = shape[, 1],
          y = shape[, 2],
          n = shape[, 6],
          frame = frame_number,
          id = 1:nrow(shape),
          track = NA,
          width = shape[, 3],
          height = shape[, 4],
          angle = shape[, 5]
        )

        memory <<- memory[frame >= (frame_number - input$look_back_x)]
        blobs <- simplerTracker(blobs, memory, maxDist = input$max_dist_x)
        newTrack <- is.na(blobs$track)

        if (sum(newTrack) > 0) {
          blobs$track[newTrack] <- seq(mt + 1, mt + sum(newTrack), 1)
          mt <<- mt + sum(newTrack)
        }

        memory <<- rbind(memory, blobs)

        to_write <- blobs[, -"id"]
        to_write[, class := "object"]
        data.table::setcolorder(
          to_write,
          c(
            "frame",
            "track",
            "class",
            "x",
            "y",
            "width",
            "height",
            "angle",
            "n"
          )
        )

        if (!is.null(scale_px()) & !is.null(scale_real())) {
          if (!is.na(scale_real())) {
            to_write[,
              paste0(c("x", "y", "width", "height"), "_", unit_real()) := .(
                (x - origin()[1]) * scale_real() / scale_px(),
                (y - origin()[2]) * scale_real() / scale_px(),
                width * scale_real() / scale_px(),
                height * scale_real() / scale_px()
              )
            ]
          }
        }

        if (loop() == 1) {
          if (file.exists(tracks_path())) {
            unlink(tracks_path())
          }
          data.table::fwrite(to_write, tracks_path(), append = FALSE)
        } else {
          data.table::fwrite(to_write, tracks_path(), append = TRUE)
        }

        if (input$preview_tracks_x & ((loop() %% input$look_back_x) == 0)) {
          void <- memory[
            frame == frame_number,
            .drawBox(
              to_display,
              .SD$x,
              .SD$y,
              .SD$width,
              .SD$height,
              .SD$angle,
              color = .shades[, (.BY$track %% ncol(.shades)) + 1],
              contrast = c(255, 255, 255),
              thickness = max(1, round(sc)),
              outline = max(1, round(sc) + 1)
            ),
            by = .(track)
          ]

          void <- memory[,
            .drawPolyLine(
              to_display,
              cbind(.SD$x, .SD$y),
              closed = FALSE,
              color = .shades[, (.BY$track %% ncol(.shades)) + 1],
              contrast = c(255, 255, 255),
              thickness = max(1, round(sc)),
              outline = max(1, round(sc) + 1)
            ),
            by = .(track)
          ]

          refresh_display(refresh_display() + 1)
        }
      }

      new_check <- floor(100 * loop() / n)
      if (new_check > old_check) {
        new_time <- Sys.time()
        fps <- (loop() - old_frame + 1) /
          as.numeric(difftime(new_time, old_time, units = "secs"))
        old_check <<- new_check
        old_frame <<- loop()
        old_time <<- new_time
        pb$set(
          value = new_check / 100,
          detail = paste0(new_check, "% - ", round(fps, digits = 2), "fps")
        )
      }

      loop(loop() + 1)
    } else {
      loop(0)
      pb$close()
      shiny::removeNotification(id = "tracking")
      shinyjs::hideElement("curtain")
    }
  }
})

shiny::observeEvent(input$escKey, {
  if (loop() > 0) {
    done <- loop() - 1
    loop(0)
    pb$close()
    shiny::removeNotification(id = "tracking")
    shinyjs::hideElement("curtain")
    shiny::showNotification(
      paste0("Tracking canceled after ", done, " of ", n, " frames."),
      type = "warning"
    )
  }
})
