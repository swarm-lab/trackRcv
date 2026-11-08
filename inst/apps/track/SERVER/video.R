# Globals and reactives
volumes <- c(Home = fs::path_home(), shinyFiles::getVolumes()())
the_video <- NULL
the_bulk_video <- NULL
the_image <- NULL

default_root <- shiny::reactiveVal()
default_path <- shiny::reactiveVal("")
video_path <- shiny::reactiveVal()
refresh_video <- shiny::reactiveVal(0)

visible <- shiny::reactive({
  refresh_video()
  isTRUE(input$main %in% c("1", "4", "5", "6")) && is_video_capture(the_video)
})

video <- shiny::reactive({
  refresh_video()
  the_video
})

frame_position <- frame_position_range_server("fp", video, visible)

shiny::observeEvent(visible(), {
  if (isTRUE(visible())) {
    shinyjs::show("controls_legend")
  } else {
    shinyjs::hide("controls_legend")
  }
})


# UI
output$video_status <- shiny::renderUI({
  if (refresh_display() > -1 & !is_video_capture(the_video)) {
    shiny::p("Video missing (and required).", class = "bad")
  } else if (!is_video_capture(the_video)) {
    shiny::p("Incompatible videos.", class = "bad")
  } else {
    NULL
  }
})

shiny::observeEvent(refresh_display(), {
  if (!is_video_capture(the_video)) {
    .toggleTabs(2:7, "OFF")
    toggled_tabs$toggled[2:7] <<- FALSE
  } else {
    if (toggled_tabs$toggled[2] == FALSE) {
      .toggleTabs(2, "ON")
      toggled_tabs$toggled[2] <<- TRUE
    }
  }
})


# Display
shiny::observeEvent(input$main, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(refresh_display(), {
  if (input$main == "1") {
    if (is_image(the_image)) {
      to_display <<- the_image$copy()
    } else {
      to_display <<- black_screen$copy()
    }

    print_display(print_display() + 1)
  }
})

output$display <- shiny::renderUI({
  if (print_display() > 0) {
    if (is_image(to_display)) {
      shiny::tags$img(
        src = paste0(
          "data:image/jpg;base64,",
          reticulate::py_to_r(
            base64$b64encode(cv2$imencode(".jpg", to_display)[1])$decode(
              "utf-8"
            )
          )
        ),
        width = "100%",
        id = "display_img",
        draggable = "false"
      )
    } else {
      shiny::tags$img(
        src = paste0(
          "data:image/jpg;base64,",
          reticulate::py_to_r(
            base64$b64encode(cv2$imencode(".jpg", black_screen)[1])$decode(
              "utf-8"
            )
          )
        ),
        width = "100%",
        id = "display_img",
        draggable = "false"
      )
    }
  }
})

session$onFlushed(
  function() {
    js$uishape("display_img")
    js$imgshape("display_img")
  },
  once = FALSE
)

shiny::observeEvent(input$win_resize, {
  js$uishape("display_img")
  js$imgshape("display_img")
})


# Load video
shinyFiles::shinyFileChoose(
  input,
  "video_file",
  roots = volumes,
  session = session,
  defaultRoot = default_root(),
  defaultPath = default_path()
)

shiny::observeEvent(input$video_file, {
  path <- shinyFiles::parseFilePaths(volumes, input$video_file)
  if (nrow(path) > 0) {
    video_path(normalizePath(path$datapath, mustWork = FALSE))
  }
})

shiny::observeEvent(video_path(), {
  ix <- which.max(
    sapply(
      stringr::str_locate_all(
        video_path(),
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

  if (length(volume) > 0) {
    dir <- dirname(video_path())
    default_root(names(volumes)[ix])
    default_path(gsub(paste0(".*", volume), "", dir))
  }
})

shiny::observeEvent(video_path(), {
  to_check <- open_display_video_handle(video_path())

  n <- if (reticulate::py_to_r(to_check$isOpened())) {
    n_frames(to_check)
  } else {
    NA
  }

  if (!is.na(n) && n > 1) {
    the_video <<- to_check
    the_bulk_video <<- open_bulk_video_handle(video_path())
    the_image <<- the_video$read()[1]
  } else {
    the_video <<- NULL
    the_bulk_video <<- NULL
    the_image <<- NULL
  }

  refresh_video(refresh_video() + 1)
  refresh_display(refresh_display() + 1)
})


# Read frame
shiny::observeEvent(frame_position$current_frame(), {
  if (is_video_capture(the_video) && frame_position$current_frame() >= 1) {
    the_image <<- read_frame(the_video, frame_position$current_frame())
    refresh_display(refresh_display() + 1)
  }
})
