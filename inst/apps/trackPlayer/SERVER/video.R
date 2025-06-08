# Globals and reactives
volumes <- c(Home = fs::path_home(), getVolumes()())
video_range <- c(0, 0)
the_video <- NULL
the_image <- NULL
the_tracks <- NULL
col_names <- c("x", "y", "n", "frame", "track", "width", "height", "angle")
col_types <- rep("numeric", length(col_names))
names(col_types) <- col_names

default_root <- shiny::reactiveVal()
default_path <- shiny::reactiveVal("")
video_path <- shiny::reactiveVal()
tracks_path <- shiny::reactiveVal()
export_path <- shiny::reactiveVal()
the_frame <- shiny::reactiveVal()
refresh_video <- shiny::reactiveVal(0)


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

shiny::observeEvent(input$track_width_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$track_length_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$tag_scale_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(input$tag_width_x, {
  refresh_display(refresh_display() + 1)
})

shiny::observeEvent(refresh_display(), {
  if (input$main == "1") {
    if (is_image(the_image)) {
      to_display <<- the_image$copy()
      sc <- max(c(n_row(to_display), n_col(to_display)) / 720)

      if (data.table::is.data.table(the_tracks)) {
        current_tracks <- the_tracks[frame == the_frame()]$track_fixed
        dt <- the_tracks[
          frame <= the_frame() &
            frame >= (the_frame() - input$track_length_x) &
            track_fixed %in% current_tracks
        ]

        void <- dt[
          frame == the_frame(),
          .drawBox(
            to_display,
            .SD$x,
            .SD$y,
            .SD$width,
            .SD$height,
            .SD$angle,
            .shades[, (.BY$track_fixed %% ncol(.shades)) + 1],
            c(255, 255, 255),
            input$track_width_x
          ),
          by = .(track_fixed)
        ]

        if (input$show_tracks == "Yes") {
          void <- dt[,
            .drawPolyLine(
              to_display,
              cbind(.SD$x, .SD$y),
              FALSE,
              .shades[, (.BY$track_fixed %% ncol(.shades)) + 1],
              c(255, 255, 255),
              input$track_width_x
            ),
            by = .(track_fixed),
            .SDcols = c("x", "y")
          ]
        }

        if (input$show_id == "Yes") {
          void <- dt[
            frame == the_frame(),
            .drawTag(
              to_display,
              .BY$track_fixed,
              .SD$x,
              .SD$y,
              input$tag_scale_x,
              c(255, 255, 255),
              c(0, 0, 0),
              input$tag_width_x
            ),
            by = .(track_fixed)
          ]
        }
      }
    } else {
      to_display <<- black_screen$copy()
    }

    js$uishape("display_img")
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

session$onFlushed(function() {
  js$uishape("display_img")
})

shiny::observeEvent(input$win_resize, {
  js$uishape("display_img")
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
  to_check <- cv2$VideoCapture(video_path())

  if (reticulate::py_to_r(to_check$isOpened())) {
    if (!is.na(n_frames(to_check))) {
      if (n_frames(to_check) > 1) {
        the_video <<- to_check
        the_image <<- the_video$read()[1]
        refresh_video(refresh_video() + 1)
        refresh_display(refresh_display() + 1)
      }
    }
  }
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
shiny::observeEvent(input$video_controls_x, {
  if (is_video_capture(the_video)) {
    the_frame(input$video_controls_x[2])
  }
})

shiny::observeEvent(the_frame(), {
  if (!is.null(the_frame())) {
    the_image <<- read_frame(the_video, the_frame())
    refresh_display(refresh_display() + 1)
  }
})

shiny::observeEvent(input$leftKey, {
  shinyjs::click("minus_frame", asis = FALSE)
})

shiny::observeEvent(input$minus_frame, {
  if (is_video_capture(the_video)) {
    vals <- input$video_controls_x

    if (vals[2] > vals[1]) {
      vals[2] <- vals[2] - 1
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    }
  }
})

shiny::observeEvent(input$rightKey, {
  shinyjs::click("plus_frame", asis = FALSE)
})

shiny::observeEvent(input$plus_frame, {
  if (is_video_capture(the_video)) {
    vals <- input$video_controls_x

    if (vals[2] < vals[3]) {
      vals[2] <- vals[2] + 1
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    }
  }
})

shiny::observeEvent(input$downKey, {
  shinyjs::click("minus_sec", asis = FALSE)
})

shiny::observeEvent(input$minus_sec, {
  if (is_video_capture(the_video)) {
    vals <- input$video_controls_x

    if (vals[2] >= (vals[1] + fps(the_video))) {
      vals[2] <- vals[2] - fps(the_video)
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    } else {
      vals[2] <- vals[1]
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    }
  }
})

shiny::observeEvent(input$upKey, {
  shinyjs::click("plus_sec", asis = FALSE)
})

shiny::observeEvent(input$plus_sec, {
  if (is_video_capture(the_video)) {
    vals <- input$video_controls_x

    if (vals[2] <= (vals[3] - fps(the_video))) {
      vals[2] <- vals[2] + fps(the_video)
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    } else {
      vals[2] <- vals[3]
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    }
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
    shiny::showNotification("Exporting video.", id = "exporting", duration = NULL)

    n <- input$video_controls_x[3] - input$video_controls_x[1] + 1
    the_video$set(cv2$CAP_PROP_POS_FRAMES, input$video_controls_x[1] - 1)
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

    for (i in 1:n) {
      to_export <- the_video$read()[1]
      current_frame <- reticulate::py_to_r(the_video$get(
        cv2$CAP_PROP_POS_FRAMES
      ))

      if (data.table::is.data.table(the_tracks)) {
        current_tracks <- the_tracks[frame == current_frame]$track_fixed
        dt <- the_tracks[
          frame <= current_frame &
            frame >= (current_frame - input$track_length_x) &
            track_fixed %in% current_tracks
        ]

        void <- dt[
          frame == current_frame,
          .drawBox(
            to_export,
            .SD$x,
            .SD$y,
            .SD$width,
            .SD$height,
            .SD$angle,
            .shades[, (.BY$track_fixed %% ncol(.shades)) + 1],
            c(255, 255, 255),
            input$track_width_x
          ),
          by = .(track_fixed)
        ]

        if (input$show_tracks == "Yes") {
          void <- dt[,
            .drawPolyLine(
              to_export,
              cbind(.SD$x, .SD$y),
              FALSE,
              .shades[, (.BY$track_fixed %% ncol(.shades)) + 1],
              c(255, 255, 255),
              input$track_width_x
            ),
            by = .(track_fixed),
          ]
        }

        if (input$show_id == "Yes") {
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
              input$track_width_x
            ),
            by = .(track_fixed)
          ]
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
