# Globals and reactives
volumes <- c(Home = fs::path_home(), getVolumes()())
the_video <- NULL
the_image <- NULL
the_tracks <- NULL
col_names <- c("x", "y", "frame", "track", "width", "height", "angle")
col_types <- rep("numeric", length(col_names))
names(col_types) <- col_names

default_root <- shiny::reactiveVal()
default_path <- shiny::reactiveVal("")
video_path <- shiny::reactiveVal()
tracks_path <- shiny::reactiveVal()
export_path <- shiny::reactiveVal()
refresh_video <- shiny::reactiveVal(0)

visible <- shiny::reactive({
  refresh_video()
  is_video_capture(the_video)
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

output$tracks_status <- shiny::renderUI({
  if (refresh_display() > -1 & !data.table::is.data.table(the_tracks)) {
    shiny::p("Tracks missing (and required).", class = "bad")
  } else {
    NULL
  }
})


# Display
shiny::observeEvent(input$main, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$line_width_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$outline_width_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$track_length_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$tag_scale_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$show_id, {
  if (input$show_id & input$show_class) {
    shinyWidgets::updatePrettyToggle(session, "show_class", value = FALSE)
  }

  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$show_class, {
  if (input$show_id & input$show_class) {
    shinyWidgets::updatePrettyToggle(session, "show_id", value = FALSE)
  }

  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$show_box, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$show_track, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(refresh_display(), {
  if (input$main == "1") {
    if (is_image(the_image)) {
      to_display <<- the_image$copy()
      sc <- max(c(n_row(to_display), n_col(to_display)) / 720)

      if (data.table::is.data.table(the_tracks)) {
        current_tracks <- the_tracks[
          frame == frame_position$current_frame() & !ignore
        ]$track_fixed

        if (length(current_tracks) > 0) {
          dt <- the_tracks[
            frame <= frame_position$current_frame() &
              frame >= (frame_position$current_frame() - input$track_length_x) # &
            # track_fixed %in% current_tracks
          ]

          if (input$show_box) {
            void <- dt[
              frame == frame_position$current_frame(),
              .drawBox(
                to_display,
                .SD$x,
                .SD$y,
                .SD$width,
                .SD$height,
                .SD$angle,
                color = if (tolower(.SD$class) %in% colors()) {
                  col2rgb(tolower(.SD$class))[3:1, ]
                } else {
                  .shades[3:1, (.BY$track_fixed %% ncol(.shades)) + 1]
                },
                contrast = c(255, 255, 255),
                thickness = input$line_width_x,
                outline = input$outline_width_x
              ),
              by = .(track_fixed)
            ]
          }

          if (input$show_track) {
            void <- dt[,
              .drawPolyLine(
                to_display,
                cbind(.SD$x, .SD$y),
                closed = FALSE,
                color = if (tolower(.SD$class[.N]) %in% colors()) {
                  col2rgb(tolower(.SD$class[.N]))[3:1, ]
                } else {
                  .shades[3:1, (.BY$track_fixed %% ncol(.shades)) + 1]
                },
                contrast = c(255, 255, 255),
                thickness = input$line_width_x,
                outline = input$outline_width_x
              ),
              by = .(track_fixed)
            ]
          }

          if (input$show_id) {
            void <- dt[
              frame == frame_position$current_frame(),
              .drawTag(
                to_display,
                .BY$track_fixed,
                .SD$x,
                .SD$y,
                input$tag_scale_x,
                c(255, 255, 255),
                c(0, 0, 0),
                input$tag_scale_x * 2,
                input$tag_scale_x * 2 + 1
              ),
              by = .(track_fixed)
            ]
          }

          if (input$show_class) {
            void <- dt[
              frame == frame_position$current_frame(),
              .drawTag(
                to_display,
                .SD$class,
                .SD$x,
                .SD$y,
                input$tag_scale_x,
                c(255, 255, 255),
                c(0, 0, 0),
                input$tag_scale_x * 2,
                input$tag_scale_x * 2 + 1
              ),
              by = .(track_fixed)
            ]
          }
        }
      }
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
    the_image <<- the_video$read()[1]
  } else {
    the_video <<- NULL
    the_image <<- NULL
  }

  refresh_video(refresh_video() + 1)
  refresh_display(refresh_display() + 1)
})


# Load tracks
shinyFiles::shinyFileChoose(
  input,
  "tracks_file",
  roots = volumes,
  session = session,
  defaultRoot = default_root(),
  defaultPath = default_path()
)

shiny::observeEvent(input$tracks_file, {
  path <- shinyFiles::parseFilePaths(volumes, input$tracks_file)
  if (nrow(path) > 0) {
    tracks_path(normalizePath(path$datapath, mustWork = FALSE))
  }
})

shiny::observeEvent(tracks_path(), {
  ix <- which.max(
    sapply(
      stringr::str_locate_all(
        tracks_path(),
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
    dir <- dirname(tracks_path())
    default_root(names(volumes)[ix])
    default_path(gsub(paste0(".*", volume), "", dir))
  }
})

shiny::observeEvent(tracks_path(), {
  to_check <- tryCatch(
    data.table::fread(tracks_path(), colClasses = col_types),
    error = function(e) NA
  )

  if (all(col_names %in% names(to_check))) {
    if (any(!(c("ignore", "track_fixed") %in% names(to_check)))) {
      to_check[, c("ignore", "track_fixed") := list(FALSE, track)]
    }
    the_tracks <<- to_check
  }

  refresh_display(refresh_display() + 1)
})


# Read frame
shiny::observeEvent(frame_position$current_frame(), {
  if (is_video_capture(the_video) && frame_position$current_frame() >= 1) {
    the_image <<- read_frame(the_video, frame_position$current_frame())
    refresh_display(refresh_display() + 1)
  }
})


# Export video
shinyFiles::shinyFileSave(
  input,
  "export_video",
  roots = volumes,
  session = session,
  defaultRoot = default_root(),
  defaultPath = default_path()
)

shiny::observeEvent(input$export_video, {
  path <- shinyFiles::parseSavePath(volumes, input$export_video)
  export_path(path$datapath)
})

shiny::observeEvent(export_path(), {
  if (is_video_capture(the_video) & length(export_path()) > 0) {
    shinyjs::showElement("curtain")
    shiny::showNotification(
      "Exporting video.",
      id = "exporting",
      duration = NULL
    )

    export_range <- frame_position$frame_range()
    n <- export_range[2] - export_range[1] + 1
    the_video$set(cv2$CAP_PROP_POS_FRAMES, export_range[1] - 1)
    sc <- max(c(n_row(to_display), n_col(to_display)) / 720)

    vw <- cv2$VideoWriter(
      normalizePath(export_path(), mustWork = FALSE),
      fourcc("avc1"),
      fps(the_video),
      as.integer(c(
        n_col(the_video),
        n_row(the_video)
      ))
    )

    if (!reticulate::py_to_r(vw$isOpened())) {
      vw <- cv2$VideoWriter(
        normalizePath(export_path(), mustWork = FALSE),
        fourcc("mp4v"),
        fps(the_video),
        as.integer(c(
          n_col(the_video),
          n_row(the_video)
        ))
      )
    }

    pb <- shiny::Progress$new()
    pb$set(message = "Processing: ", value = 0, detail = "0%")
    old_check <- 0
    old_frame <- 1
    old_time <- Sys.time()

    for (i in seq_len(n)) {
      to_export <- the_video$read()[1]
      current_frame <- reticulate::py_to_r(the_video$get(
        cv2$CAP_PROP_POS_FRAMES
      ))

      if (data.table::is.data.table(the_tracks)) {
        current_tracks <- the_tracks[
          frame == current_frame & !ignore
        ]$track_fixed

        if (length(current_tracks) > 0) {
          dt <- the_tracks[
            frame <= current_frame &
              frame >= (current_frame - input$track_length_x) # &
            # track_fixed %in% current_tracks
          ]

          if (input$show_box) {
            void <- dt[
              frame == current_frame,
              .drawBox(
                to_export,
                .SD$x,
                .SD$y,
                .SD$width,
                .SD$height,
                .SD$angle,
                color = if (tolower(.SD$class) %in% colors()) {
                  col2rgb(tolower(.SD$class))[3:1, ]
                } else {
                  .shades[3:1, (.BY$track_fixed %% ncol(.shades)) + 1]
                },
                contrast = c(255, 255, 255),
                thickness = input$line_width_x,
                outline = input$outline_width_x
              ),
              by = .(track_fixed)
            ]
          }

          if (input$show_track) {
            void <- dt[,
              .drawPolyLine(
                to_export,
                cbind(.SD$x, .SD$y),
                closed = FALSE,
                color = if (tolower(.SD$class[.N]) %in% colors()) {
                  col2rgb(tolower(.SD$class[.N]))[3:1, ]
                } else {
                  .shades[3:1, (.BY$track_fixed %% ncol(.shades)) + 1]
                },
                contrast = c(255, 255, 255),
                thickness = input$line_width_x,
                outline = input$outline_width_x
              ),
              by = .(track_fixed)
            ]
          }

          if (input$show_id) {
            void <- dt[
              frame == current_frame,
              .drawTag(
                to_export,
                .BY$track_fixed,
                .SD$x,
                .SD$y,
                input$tag_scale_x,
                c(255, 255, 255),
                c(0, 0, 0),
                input$tag_scale_x * 1.5,
                input$tag_scale_x * 1.5 + 1
              ),
              by = .(track_fixed)
            ]
          }

          if (input$show_class) {
            void <- dt[
              frame == current_frame,
              .drawTag(
                to_export,
                .SD$class,
                .SD$x,
                .SD$y,
                input$tag_scale_x,
                c(255, 255, 255),
                c(0, 0, 0),
                input$tag_scale_x * 2,
                input$tag_scale_x * 2 + 1
              ),
              by = .(track_fixed)
            ]
          }
        }
      }

      vw$write(to_export)

      new_check <- floor(100 * i / n)
      if (new_check > old_check) {
        new_time <- Sys.time()
        fps <- (i - old_frame + 1) /
          as.numeric(difftime(new_time, old_time, units = "secs"))
        old_check <- new_check
        old_frame <- i
        old_time <- new_time
        pb$set(
          value = new_check / 100,
          detail = paste0(new_check, "% - ", round(fps, digits = 2), "fps")
        )
      }
    }

    pb$close()
    vw$release()
    shiny::removeNotification(id = "exporting")
    shinyjs::hideElement("curtain")
  }
})
