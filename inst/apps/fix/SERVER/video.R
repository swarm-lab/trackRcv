# Globals and reactives --------------------------------------------------
volumes <- c(Home = fs::path_home(), shinyFiles::getVolumes()())
video_range <- c(0, 0)
the_video <- NULL
the_image <- NULL
the_tracks <- NULL
col_names <- c("x", "y", "frame", "track", "width", "height", "angle")
col_types <- rep("numeric", length(col_names))
names(col_types) <- col_names
changes <- list()

default_root <- shiny::reactiveVal()
default_path <- shiny::reactiveVal("")
video_path <- shiny::reactiveVal()
tracks_path <- shiny::reactiveVal()
export_path <- shiny::reactiveVal()
the_frame <- shiny::reactiveVal()
refresh_video <- shiny::reactiveVal(0)
refresh_stats <- shiny::reactiveVal(0)
errors <- shiny::reactiveVal()


# UI ---------------------------------------------------------------------
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


# Display ----------------------------------------------------------------
shiny::observeEvent(input$main, {
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

        if (length(current_tracks) > 0) {
          void <- the_tracks[
            frame == the_frame() & ignore != TRUE,
            .drawBox(
              to_display,
              .SD$x,
              .SD$y,
              .SD$width,
              .SD$height,
              .SD$angle,
              .shades[, (.BY$track_fixed %% ncol(.shades)) + 1],
              c(255, 255, 255),
              sc * 1.5
            ),
            by = .(track_fixed)
          ]

          void <- the_tracks[
            frame == the_frame() & ignore != TRUE,
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


# Load video -------------------------------------------------------------
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


# Load tracks ------------------------------------------------------------
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

  refresh_stats(refresh_stats() + 1)
  refresh_display(refresh_display() + 1)
})


# Video navigation -------------------------------------------------------
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

# shiny::observeEvent(input$leftKey, {
#   shinyjs::click("minus_frame", asis = FALSE)
# })

# shiny::observeEvent(input$minus_frame, {
shiny::observeEvent(input$leftKey, {
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

# shiny::observeEvent(input$rightKey, {
#   shinyjs::click("plus_frame", asis = FALSE)
# })

# shiny::observeEvent(input$plus_frame, {
shiny::observeEvent(input$rightKey, {
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

# shiny::observeEvent(input$downKey, {
#   shinyjs::click("minus_sec", asis = FALSE)
# })

# shiny::observeEvent(input$minus_sec, {
shiny::observeEvent(input$downKey, {
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

# shiny::observeEvent(input$upKey, {
#   shinyjs::click("plus_sec", asis = FALSE)
# })

# shiny::observeEvent(input$plus_sec, {
shiny::observeEvent(input$upKey, {
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


# Statistics -------------------------------------------------------------
output$track_stats <- shiny::renderTable(
  {
    if (data.table::is.data.table(the_tracks) & refresh_stats() >= 0) {
      tmp <- the_tracks[ignore != TRUE][
        order(frame),
        .(first = frame[1], last = frame[.N]),
        by = .(track_fixed)
      ]
      errors(rbind(
        data.table::data.table(
          track = tmp[first > input$video_controls_x[1]]$track_fixed,
          frame = tmp[first > input$video_controls_x[1]]$first,
          type = "appears"
        ),
        data.table::data.table(
          track = tmp[last < max(the_tracks$frame)]$track_fixed,
          frame = tmp[last < max(the_tracks$frame)]$last + 1,
          type = "disappears"
        )
      )[order(frame)])

      tab <- table(the_tracks$track_fixed[!the_tracks$ignore])
      data.table::data.table(
        "Tracks" = length(tab),
        "Shortest" = min(tab),
        "Longest" = max(tab),
        "Median" = median(tab),
        check.names = FALSE
      )
    } else {
      data.table::data.table(
        "Tracks" = NA,
        "Shortest" = NA,
        "Longest" = NA,
        "Median" = NA,
        check.names = FALSE
      )
    }
  },
  striped = TRUE,
  width = "100%",
  align = "c"
)


# Fix tracks -------------------------------------------------------------

# Errors
shiny::observeEvent(
  errors(),
  {
    if (nrow(errors()) > 0) {
      choices <- c("", paste0(errors()$frame, "_", errors()$track))
      names(choices) <- c(
        "↓ Select an issue to navigate to it ↓",
        paste0(
          "Frame ",
          errors()$frame,
          ": track ",
          errors()$track,
          " ",
          errors()$type
        )
      )
    } else {
      choices <- c("")
      names(choices) <- c("No issues detected")
    }

    shiny::updateSelectInput(session, "suspect", choices = choices)
  },
  ignoreInit = TRUE
)

shiny::observeEvent(
  input$suspect,
  {
    if (is_video_capture(the_video)) {
      vals <- input$video_controls_x
      vals[2] <- as.numeric(sub("_.*", "", input$suspect))
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )
    }
  },
  ignoreInit = TRUE
)


# Reassign
shiny::observeEvent(input$qKey, {
  shinyjs::click("reassign_track", asis = FALSE)
})

shiny::observeEvent(input$reassign_track, {
  if (is_video_capture(the_video) & data.table::is.data.table(the_tracks)) {
    ids <- c(
      "",
      the_tracks[
        ignore == FALSE & frame == input$video_controls_x[2]
      ]$track_fixed
    )

    shiny::showModal(
      shiny::modalDialog(
        title = "Reassign track",
        easyClose = TRUE,

        shiny::selectInput(
          "current_ID",
          "Select track to reassign",
          ids,
          width = "100%"
        ),
        shiny::numericInput(
          "new_ID",
          "Type ID to reassign it to",
          NA,
          0,
          Inf,
          width = "100%"
        ),

        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("ok_reassign", "Reassign")
        )
      )
    )
  }
})

shiny::observeEvent(input$ok_reassign, {
  shiny::removeModal(session)

  old_id <- as.numeric(input$current_ID)
  new_id <- input$new_ID

  if (!is.na(old_id) & !is.na(new_id)) {
    ok <- !any(the_tracks[
      track_fixed == old_id | track_fixed == new_id,
      .(dup = .N > 1),
      by = frame
    ][, dup])

    if (ok) {
      idx <- the_tracks[, track_fixed] == old_id
      the_tracks[idx, track_fixed := new_id]
      changes[[length(changes) + 1]] <<- list(
        frame = input$video_controls_x[2],
        type = "reassign",
        idx = which(idx),
        revert = as.numeric(old_id)
      )
    } else {
      shinyalert::shinyalert(
        title = "ID conflict",
        text = paste0(
          "The chosen ID conflicts with an existing one.",
          "\nPlease choose another one."
        ),
        type = "error",
        timer = 3000,
        closeOnClickOutside = TRUE
      )
    }

    refresh_stats(refresh_stats() + 1)
    refresh_display(refresh_display() + 1)
  }
})

# Remove
shiny::observeEvent(input$wKey, {
  shinyjs::click("remove_track", asis = FALSE)
})

shiny::observeEvent(input$remove_track, {
  if (is_video_capture(the_video) & data.table::is.data.table(the_tracks)) {
    ids <- c(
      "",
      the_tracks[
        ignore == FALSE & frame == input$video_controls_x[2]
      ]$track_fixed
    )

    shiny::showModal(
      shiny::modalDialog(
        title = "Remove track",
        easyClose = TRUE,

        shiny::selectInput(
          "remove_ID",
          "Select track to remove",
          ids,
          width = "100%",
          selected = NA
        ),

        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("ok_remove", "Remove")
        )
      )
    )
  }
})

shiny::observeEvent(input$ok_remove, {
  shiny::removeModal(session)

  rm_id <- as.numeric(input$remove_ID)

  if (!is.na(rm_id)) {
    idx <- the_tracks[, track_fixed] == rm_id &
      the_tracks[, frame] >= input$video_controls_x[2]
    the_tracks[idx, ignore := TRUE]
    changes[[length(changes) + 1]] <<- list(
      frame = input$video_controls_x[2],
      type = "remove",
      idx = which(idx),
      revert = FALSE
    )
    refresh_stats(refresh_stats() + 1)
    refresh_display(refresh_display() + 1)
  }
})

# Swap
shiny::observeEvent(input$eKey, {
  shinyjs::click("swap_track", asis = FALSE)
})

shiny::observeEvent(input$swap_track, {
  if (is_video_capture(the_video) & data.table::is.data.table(the_tracks)) {
    ids <- c(
      "",
      the_tracks[
        ignore == FALSE & frame == input$video_controls_x[2]
      ]$track_fixed
    )

    shiny::showModal(
      shiny::modalDialog(
        title = "Swap tracks",
        easyClose = TRUE,

        shiny::tags$table(
          style = "width: 100%;",
          shiny::tags$tr(
            shiny::tags$td(
              shiny::selectInput(
                "swap_ID1",
                "Select first track",
                ids,
                selected = NA,
                width = "100%"
              ),
              class = "halfWidth"
            ),
            shiny::tags$td(
              shiny::selectInput(
                "swap_ID2",
                "Select second track",
                ids,
                selected = NA,
                width = "100%"
              ),
              class = "halfWidth"
            )
          )
        ),
        shiny::tags$p(
          "Note: the track IDs will be swapped from this point on.",
          class = "good"
        ),

        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("ok_swap", "Swap")
        )
      )
    )
  }
})

shiny::observeEvent(input$ok_swap, {
  shiny::removeModal(session)

  id1 <- as.numeric(input$swap_ID1)
  id2 <- as.numeric(input$swap_ID2)

  if (!is.na(id1) & !is.na(id2)) {
    idx1 <- the_tracks[, track_fixed] == id1 &
      the_tracks[, frame] >= input$video_controls_x[2]
    idx2 <- the_tracks[, track_fixed] == id2 &
      the_tracks[, frame] >= input$video_controls_x[2]
    the_tracks[idx1, track_fixed := id2]
    the_tracks[idx2, track_fixed := id1]
    changes[[length(changes) + 1]] <<- list(
      frame = input$video_controls_x[2],
      type = "swap",
      idx1 = which(idx1),
      idx2 = which(idx2),
      revert1 = id1,
      revert2 = id2
    )
    refresh_stats(refresh_stats() + 1)
    refresh_display(refresh_display() + 1)
  }
})

# Merge
shiny::observeEvent(input$rKey, {
  shinyjs::click("merge_track", asis = FALSE)
})

shiny::observeEvent(input$merge_track, {
  if (is_video_capture(the_video) & data.table::is.data.table(the_tracks)) {
    ids <- c(
      "",
      the_tracks[
        ignore == FALSE & frame == input$video_controls_x[2]
      ]$track_fixed
    )

    shiny::showModal(
      shiny::modalDialog(
        title = "Merge tracks",
        easyClose = TRUE,

        shiny::tags$table(
          style = "width: 100%;",
          shiny::tags$tr(
            shiny::tags$td(
              shiny::selectInput(
                "merge_ID1",
                "Select first track",
                ids,
                selected = NA,
                width = "100%"
              ),
              class = "halfWidth"
            ),
            shiny::tags$td(
              shiny::selectInput(
                "merge_ID2",
                "Select second track",
                ids,
                selected = NA,
                width = "100%"
              ),
              class = "halfWidth"
            )
          )
        ),
        shiny::tags$p("Note: the left track ID will be kept.", class = "good"),

        footer = shiny::tagList(
          shiny::modalButton("Cancel"),
          shiny::actionButton("ok_merge", "Merge")
        )
      )
    )
  }
})

shiny::observeEvent(input$ok_merge, {
  shiny::removeModal(session)

  id1 <- as.numeric(input$merge_ID1)
  id2 <- as.numeric(input$merge_ID2)

  if (!is.na(id1) & !is.na(id2)) {
    idx <- the_tracks$track_fixed == id1 | the_tracks$track_fixed == id2
    orig <- the_tracks[idx]
    n <- names(orig)
    unit_real <- gsub("x", "", n[grepl("x_", n)])

    fixed <- orig[,
      {
        ix <- track_fixed == id1
        l <- list()

        if (.N == 2) {
          ell_px <- merge_ellipses(
            c(x[1], y[1], width[1], height[1], angle[1]),
            c(x[2], y[2], width[2], height[2], angle[2]),
            5
          )

          l[["track"]] <- c(id1, id2)
          l[["x"]] <- c(ell_px[1], x[!ix])
          l[["y"]] <- c(ell_px[2], y[!ix])
          l[["width"]] <- c(ell_px[3], width[!ix])
          l[["height"]] <- c(ell_px[4], height[!ix])
          l[["angle"]] <- c(ell_px[5], angle[!ix])
          if (!is.null(l[["n"]])) {
            l[["n"]] <- c(sum(n), n[!ix])
          }

          if (length(unit_real) > 0) {
            ell_real <- merge_ellipses(
              c(
                get(paste0("x", unit_real))[1],
                get(paste0("y", unit_real))[1],
                get(paste0("width", unit_real))[1],
                get(paste0("height", unit_real))[1],
                angle[1]
              ),
              c(
                get(paste0("x", unit_real))[2],
                get(paste0("y", unit_real))[2],
                get(paste0("width", unit_real))[2],
                get(paste0("height", unit_real))[2],
                angle[2]
              ),
              5
            )

            l[[paste0("x", unit_real)]] <- c(ell_real[1], x[!ix])
            l[[paste0("y", unit_real)]] <- c(ell_real[2], y[!ix])
            l[[paste0("width", unit_real)]] <- c(
              ell_real[3],
              get(paste0("width", unit_real))[!ix]
            )
            l[[paste0("height", unit_real)]] <- c(
              ell_real[4],
              get(paste0("height", unit_real))[!ix]
            )
          }

          l[["track_fixed"]] <- c(id1, id2)
          l[["ignore"]] <- c(FALSE, TRUE)
        } else {
          l[["track"]] <- track
          l[["x"]] <- x
          l[["y"]] <- y
          l[["width"]] <- width
          l[["height"]] <- height
          l[["angle"]] <- angle
          if (!is.null(l[["n"]])) {
            l[["n"]] <- n
          }

          if (length(unit_real) > 0) {
            l[[paste0("x", unit_real)]] <- get(paste0("x", unit_real))
            l[[paste0("y", unit_real)]] <- get(paste0("y", unit_real))
            l[[paste0("width", unit_real)]] <- get(paste0("width", unit_real))
            l[[paste0("height", unit_real)]] <- get(paste0("height", unit_real))
          }

          if (ix) {
            l[["track_fixed"]] <- track_fixed
          } else {
            l[["track_fixed"]] <- id1
          }

          l[["ignore"]] <- ignore
        }

        l
      },
      by = frame
    ]

    the_tracks[idx, names(fixed) := fixed]

    changes[[length(changes) + 1]] <<- list(
      frame = input$video_controls_x[2],
      type = "merge",
      idx = which(idx),
      revert = orig
    )

    refresh_stats(refresh_stats() + 1)
    refresh_display(refresh_display() + 1)
  }
})

# Undo
shiny::observeEvent(input$aKey, {
  shinyjs::click("revert_changes", asis = FALSE)
})

shiny::observeEvent(input$revert_changes, {
  if (is_video_capture(the_video) & data.table::is.data.table(the_tracks)) {
    if (length(changes) > 0) {
      l <- length(changes)
      tmp <- the_tracks

      if (changes[[l]]$type == "reassign") {
        the_tracks[changes[[l]]$idx, track_fixed := changes[[l]]$revert]
      } else if (changes[[l]]$type == "remove") {
        the_tracks[changes[[l]]$idx, ignore := changes[[l]]$revert]
      } else if (changes[[l]]$type == "swap") {
        the_tracks[changes[[l]]$idx1, track_fixed := changes[[l]]$revert1]
        the_tracks[changes[[l]]$idx2, track_fixed := changes[[l]]$revert2]
      } else if (changes[[l]]$type == "merge") {
        the_tracks[
          changes[[l]]$idx,
          names(changes[[l]]$revert) := changes[[l]]$revert
        ]
      }

      vals <- input$video_controls_x
      vals[2] <- changes[[l]]$frame
      shinyWidgets::updateNoUiSliderInput(
        session,
        "video_controls_x",
        value = vals
      )

      changes[[l]] <<- NULL
      refresh_stats(refresh_stats() + 1)
      refresh_display(refresh_display() + 1)
    }
  }
})

# Save
shiny::observeEvent(input$sKey, {
  shinyjs::click("save_changes", asis = FALSE)
})

shiny::observeEvent(input$save_changes, {
  if (data.table::is.data.table(the_tracks)) {
    fixed_path <- paste0(
      sub(".csv|_fixed.csv", "", tracks_path()),
      "_fixed.csv"
    )
    data.table::fwrite(the_tracks, fixed_path)
    shiny::showNotification(
      paste0("Changes saved at ", fixed_path),
      id = "save",
      duration = 2
    )
  }
})
