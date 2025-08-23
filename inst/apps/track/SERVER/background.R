# Globals and reactives
the_background <- NULL
ghost_coords <- NULL

refresh_background <- shiny::reactiveVal(0)
collect_ghost <- shiny::reactiveVal(0)
stop_ghost_collection <- shiny::reactiveVal(0)
background_path <- shiny::reactiveVal()


# UI
output$background_status <- shiny::renderUI({
  if (
    (refresh_display() > -1 | input$compute_background > -1) &
      !is_image(the_background)
  ) {
    shiny::p("Background missing (and required).", class = "bad")
  } else {
    NULL
  }
})

shiny::observeEvent(refresh_display(), {
  if (!is_image(the_background)) {
    .toggleTabs(3:7, "OFF")
    toggled_tabs$toggled[3:7] <<- FALSE
  } else {
    if (toggled_tabs$toggled[3] == FALSE) {
      .toggleTabs(3, "ON")
      toggled_tabs$toggled[3] <<- TRUE
    }
  }
})


# Display
shiny::observeEvent(refresh_display(), {
  if (input$main == "2") {
    if (is_image(the_background)) {
      to_display <<- the_background$copy()
      sc <- max(
        c(n_row(to_display), n_col(to_display)) / 720
      )
      r <- 0.01 * min(n_row(to_display), n_col(to_display))

      if (collect_ghost() > 0) {
        if (nrow(ghost_coords) > 1) {
          .drawPolyLine(
            to_display,
            ghost_coords,
            closed = TRUE,
            color = c(255, 255, 255),
            contrast = c(0, 0, 0),
            thickness = max(1, round(sc)),
            outline = max(1, round(sc))
          )
        }

        if (nrow(ghost_coords) > 0) {
          for (i in seq_len(nrow(ghost_coords))) {
            .drawCircle(
              to_display,
              ghost_coords[i, 1],
              ghost_coords[i, 2],
              radius = r,
              color = c(0, 0, 255),
              contrast = c(255, 255, 255),
              thickness = max(1, round(sc))
            )
          }
        }
      }
    } else {
      to_display <<- black_screen$copy()
    }

    print_display(print_display() + 1)
  }
})


# Load existing background
shinyFiles::shinyFileChoose(
  input,
  "background_file",
  roots = volumes,
  session = session,
  defaultRoot = default_root(),
  defaultPath = default_path()
)

shiny::observeEvent(input$background_file, {
  path <- shinyFiles::parseFilePaths(volumes, input$background_file)
  if (nrow(path) > 0) {
    background_path(normalizePath(path$datapath, mustWork = FALSE))
    refresh_background(refresh_background() + 1)
  }
})

shiny::observeEvent(refresh_background(), {
  if (refresh_background() > 0) {
    to_check <- cv2$imread(background_path())

    if (is_image(to_check)) {
      if (
        !all(
          unlist(reticulate::py_to_r(to_check$shape)) ==
            unlist(reticulate::py_to_r(the_image$shape))
        )
      ) {
        shinyalert::shinyalert(
          "Error:",
          "The video and background do not have the same shape.",
          type = "error",
          animation = FALSE,
          closeOnClickOutside = TRUE
        )
        the_background <<- NULL
      } else {
        the_background <<- to_check$copy()
      }

      ix <- which.max(
        sapply(
          stringr::str_locate_all(
            background_path(),
            stringr::fixed(sapply(volumes, normalizePath))
          ),
          function(l) {
            if (nrow(l) > 0) {
              diff(l[1, ])
            } else {
              NA
            }
          }
        )
      )

      volume <- volumes[ix]
      dir <- dirname(background_path())
      default_root(names(volumes)[ix])
      default_path(gsub(paste0(".*", volume), "", dir))

      refresh_display(refresh_display() + 1)
    }
  }
})


# Compute background estimate
shiny::observeEvent(input$compute_background, {
  if (is_video_capture(the_video)) {
    shinyjs::showElement("curtain")
    the_background <<- np$uint8(
      backgrounder(
        the_video,
        n = input$background_images_x,
        method = input$background_type_x,
        start = input$video_controls_x[1],
        end = input$video_controls_x[3]
      )
    )

    shinyjs::hideElement("curtain")
    refresh_display(refresh_display() + 1)
  }
})


# Remove ghosts
shiny::observeEvent(input$ghost_button, {
  if (is_image(the_background)) {
    .toggleInputs(input, "OFF")
    .toggleTabs(1, "OFF")

    shiny::showNotification(
      "Click to draw a polygon around the object to remove from
                     the image. Enter to stop. Esc to cancel.",
      id = "ghost_notif",
      duration = NULL,
      type = "message"
    )

    shinyjs::addClass("display", "active_display")
    collect_ghost(1)
  }
})

shinyjs::onevent("click", "display_img", function(props) {
  px <- trackRcv::n_col(to_display) *
    ((props$offsetX -
      (input$display_img_uiwidth - input$display_img_imgwidth) / 2) /
      input$display_img_imgwidth)
  py <- trackRcv::n_row(to_display) *
    (props$offsetY / input$display_img_imgheight)

  if (collect_ghost() > 0) {
    ghost_coords <<- rbind(ghost_coords, c(px, py))
    refresh_display(refresh_display() + 1)
  } else if (collect_mask() > 0) {
    mask_coords <<- rbind(mask_coords, c(px, py))
    if (collect_mask() == 2 & nrow(mask_coords) >= 5) {
      stop_mask_collection(stop_mask_collection() + 1)
    }
    refresh_display(refresh_display() + 1)
  } else if (collect_origin() > 0) {
    origin(c(px, py))
    stop_origin_collection(stop_origin_collection() + 1)
    refresh_display(refresh_display() + 1)
  } else if (collect_scale() > 0) {
    scale_coords <<- rbind(scale_coords, c(px, py))
    if (nrow(scale_coords) >= 2) {
      stop_scale_collection(stop_scale_collection() + 1)
    }
    refresh_display(refresh_display() + 1)
  }
})

shiny::observeEvent(input$retKey, {
  if (collect_ghost() > 0) {
    stop_ghost_collection(stop_ghost_collection() + 1)
  }
})

shiny::observeEvent(input$escKey, {
  if (collect_ghost() > 0) {
    ghost_coords <<- NULL
    stop_ghost_collection(stop_ghost_collection() + 1)
  }
})

shiny::observeEvent(stop_ghost_collection(), {
  if (collect_ghost() > 0) {
    if (!is.null(ghost_coords)) {
      roi <- reticulate::np_array(
        array(
          0L,
          c(n_row(the_background), n_col(the_background), 1)
        ),
        dtype = "uint8"
      )
      cv2$fillPoly(
        roi,
        pts = array(as.integer(ghost_coords), c(1, dim(ghost_coords))),
        color = c(255, 255, 255)
      )
      the_background <<- cv2$inpaint(the_background, roi, 5, cv2$INPAINT_TELEA)
    }

    shiny::removeNotification(id = "ghost_notif")
    .toggleInputs(input, "ON")
    .toggleTabs(1, "ON")
    shinyjs::removeClass("display", "active_display")
    collect_ghost(0)
    ghost_coords <<- NULL
    refresh_display(refresh_display() + 1)
  }
})


# Save background
shinyFiles::shinyFileSave(
  input,
  "save_background",
  roots = volumes,
  session = session,
  defaultRoot = default_root(),
  defaultPath = default_path()
)

shiny::observeEvent(input$save_background, {
  path <- shinyFiles::parseSavePath(volumes, input$save_background)

  if (is_image(the_background) & nrow(path) > 0) {
    path <- normalizePath(path$datapath, mustWork = FALSE)
    cv2$imwrite(path, the_background)
    background_path(path)
  }
})
