# Move `value` by `delta`, staying within `[lower, upper]`.
.trk_step_clamp <- function(value, delta, lower, upper) {
  min(max(value + delta, lower), upper)
}

# Slider range/value to apply to the range variant on a video-load event.
# `restore_range` is the analysis window saved in a restored session, or
# `NULL` outside of a session restore.
.trk_range_reset_target <- function(video, restore_range) {
  if (is_video_capture(video)) {
    if (!is.null(restore_range)) {
      value <- c(restore_range[1], restore_range[1], restore_range[2])
    } else {
      value <- c(1, 1, n_frames(video))
    }
    list(range = c(1, n_frames(video)), value = value)
  } else {
    list(range = c(0, 0), value = c(0, 0, 0))
  }
}

# Slider range/value to apply to the scalar variant on a video-load event.
.trk_scalar_reset_target <- function(video) {
  if (is_video_capture(video)) {
    list(range = c(1, n_frames(video)), value = 1)
  } else {
    list(range = c(0, 0), value = 0)
  }
}


#' @title Frame-Position Control UI (Range Variant)
#'
#' @description This function creates the UI for a frame-position control
#'  with an adjustable analysis window (a start and end frame), for apps such
#'  as `track` and `visualize`. Pair it with
#'  [frame_position_range_server()] using the same `id`.
#'
#' @param id A character string uniquely identifying the control's namespace
#'  within the app.
#'
#' @param color A character string giving the CSS color for the control's
#'  connect bar, or `NULL` (the default) to use the control's own default
#'  color.
#'
#' @param pips A list of pip (tick mark) options passed to
#'  [shinyWidgets::noUiSliderInput()], or `NULL` (the default) to render no
#'  pip tick marks.
#'
#' @return A UI object that can be included in a Shiny app's UI.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [frame_position_range_server()]
#'
#' @export
frame_position_range_ui <- function(id, color = NULL, pips = NULL) {
  ns <- shiny::NS(id)
  shinyjs::hidden(
    shiny::div(
      id = ns("frame_position_container"),
      shinyWidgets::noUiSliderInput(
        ns("frame_position_slider"),
        NULL,
        0,
        0,
        c(0, 0, 0),
        step = 1,
        width = "100%",
        color = color,
        pips = pips,
        tooltips = TRUE,
        format = shinyWidgets::wNumbFormat(decimals = 0)
      )
    )
  )
}


#' @title Frame-Position Control Server (Range Variant)
#'
#' @description This function implements the server logic for a
#'  frame-position control with an adjustable analysis window (a start and
#'  end frame), for apps such as `track` and `visualize`. Pair it with
#'  [frame_position_range_ui()] using the same `id`.
#'
#' @param id A character string uniquely identifying the control's namespace
#'  within the app. Must match the `id` passed to [frame_position_range_ui()].
#'
#' @param video A reactive expression returning the Python VideoCapture object
#'  currently used for live display, or `NULL`/an invalid object when no
#'  video is loaded.
#'
#' @param visible A reactive expression returning `TRUE` when the control
#'  should be shown, and `FALSE` when it should be hidden.
#'
#' @return A list with three elements: `current_frame`, a reactive expression
#'  returning the frame currently displayed; `frame_range`, a reactive
#'  expression returning a two-element numeric vector with the start and end
#'  of the analysis window; and `set_frame`, a function taking a single
#'  numeric frame number to request as the new current frame.
#'
#' @details
#' If the app that embeds this control also enables session bookmarking, the
#'  analysis window is saved when the session is bookmarked and restored when
#'  the session is restored. A video load that is not part of a session
#'  restore resets the analysis window to the full length of the video.
#'
#' The host app must call `shinyjs::useShinyjs()` once in its UI, since the
#'  control's visibility is implemented with `shinyjs::show()`/`hide()`.
#'
#' Keyboard stepping listens for the top-level (non-namespaced) Shiny inputs
#'  `leftKey`, `rightKey`, `upKey`, and `downKey`. The host app is
#'  responsible for setting these via `Shiny.onInputChange()` on the
#'  corresponding arrow-key `keydown` events, guarded by
#'  `document.activeElement === document.body` so that an arrow key does not
#'  also step the control while a slider handle has keyboard focus (see
#'  `inst/apps/share/js/keyboard.js` for the historic apps' convention).
#'  Without that wiring, keyboard stepping has no effect.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [frame_position_range_ui()], [frame_position_scalar_server()]
#'
#' @export
frame_position_range_server <- function(id, video, visible) {
  shiny::moduleServer(id, function(input, output, session) {
    root <- session$rootScope()
    slider_state <- shiny::reactiveVal(c(0, 0, 0))
    pending_restore <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$frame_position_slider, {
      slider_state(input$frame_position_slider)
    })

    shiny::observeEvent(visible(), {
      if (isTRUE(visible())) {
        shinyjs::show("frame_position_container")
      } else {
        shinyjs::hide("frame_position_container")
      }
    })

    shiny::observeEvent(
      video(),
      {
        target <- .trk_range_reset_target(video(), pending_restore())
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          range = target$range,
          value = target$value
        )
        if (is_video_capture(video())) {
          pending_restore(NULL)
        }
      },
      ignoreNULL = FALSE
    )

    shiny::observeEvent(root$input$leftKey, {
      vals <- slider_state()
      if (vals[2] > vals[1]) {
        vals[2] <- vals[2] - 1
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = vals
        )
      }
    })

    shiny::observeEvent(root$input$rightKey, {
      vals <- slider_state()
      if (vals[2] < vals[3]) {
        vals[2] <- vals[2] + 1
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = vals
        )
      }
    })

    shiny::observeEvent(root$input$downKey, {
      if (is_video_capture(video())) {
        vals <- slider_state()
        vals[2] <- .trk_step_clamp(vals[2], -fps(video()), vals[1], vals[3])
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = vals
        )
      }
    })

    shiny::observeEvent(root$input$upKey, {
      if (is_video_capture(video())) {
        vals <- slider_state()
        vals[2] <- .trk_step_clamp(vals[2], fps(video()), vals[1], vals[3])
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = vals
        )
      }
    })

    session$onBookmark(function(state) {
      vals <- slider_state()
      state$values$frame_range <- c(vals[1], vals[3])
    })

    session$onRestore(function(state) {
      if (!is.null(state$values$frame_range)) {
        pending_restore(state$values$frame_range)
      }
    })

    list(
      current_frame = shiny::reactive(slider_state()[2]),
      frame_range = shiny::reactive(c(slider_state()[1], slider_state()[3])),
      set_frame = function(n) {
        vals <- slider_state()
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = c(vals[1], n, vals[3])
        )
      }
    )
  })
}


#' @title Frame-Position Control UI (Scalar Variant)
#'
#' @description This function creates the UI for a frame-position control
#'  with a single current frame and no analysis window, for apps such as
#'  `fix`. Pair it with [frame_position_scalar_server()] using the same `id`.
#'
#' @param id A character string uniquely identifying the control's namespace
#'  within the app.
#'
#' @param color A character string giving the CSS color for the control's
#'  connect bar, or `NULL` (the default) to use the control's own default
#'  color.
#'
#' @param pips A list of pip (tick mark) options passed to
#'  [shinyWidgets::noUiSliderInput()], or `NULL` (the default) to render no
#'  pip tick marks.
#'
#' @return A UI object that can be included in a Shiny app's UI.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [frame_position_scalar_server()]
#'
#' @export
frame_position_scalar_ui <- function(id, color = NULL, pips = NULL) {
  ns <- shiny::NS(id)
  shinyjs::hidden(
    shiny::div(
      id = ns("frame_position_container"),
      shinyWidgets::noUiSliderInput(
        ns("frame_position_slider"),
        NULL,
        0,
        0,
        0,
        step = 1,
        width = "100%",
        color = color,
        pips = pips,
        tooltips = TRUE,
        format = shinyWidgets::wNumbFormat(decimals = 0)
      )
    )
  )
}


#' @title Frame-Position Control Server (Scalar Variant)
#'
#' @description This function implements the server logic for a
#'  frame-position control with a single current frame and no analysis
#'  window, for apps such as `fix`. Pair it with [frame_position_scalar_ui()]
#'  using the same `id`.
#'
#' @param id A character string uniquely identifying the control's namespace
#'  within the app. Must match the `id` passed to
#'  [frame_position_scalar_ui()].
#'
#' @param video A reactive expression returning the Python VideoCapture object
#'  currently used for live display, or `NULL`/an invalid object when no
#'  video is loaded.
#'
#' @param visible A reactive expression returning `TRUE` when the control
#'  should be shown, and `FALSE` when it should be hidden.
#'
#' @return A list with two elements: `current_frame`, a reactive expression
#'  returning the frame currently displayed; and `set_frame`, a function
#'  taking a single numeric frame number to request as the new current frame.
#'
#' @details
#' The host app must call `shinyjs::useShinyjs()` once in its UI, since the
#'  control's visibility is implemented with `shinyjs::show()`/`hide()`.
#'
#' Keyboard stepping listens for the top-level (non-namespaced) Shiny inputs
#'  `leftKey`, `rightKey`, `upKey`, and `downKey`. The host app is
#'  responsible for setting these via `Shiny.onInputChange()` on the
#'  corresponding arrow-key `keydown` events, guarded by
#'  `document.activeElement === document.body` so that an arrow key does not
#'  also step the control while a slider handle has keyboard focus (see
#'  `inst/apps/share/js/keyboard.js` for the historic apps' convention).
#'  Without that wiring, keyboard stepping has no effect.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [frame_position_scalar_ui()], [frame_position_range_server()]
#'
#' @export
frame_position_scalar_server <- function(id, video, visible) {
  shiny::moduleServer(id, function(input, output, session) {
    root <- session$rootScope()
    current <- shiny::reactiveVal(0)

    shiny::observeEvent(input$frame_position_slider, {
      current(input$frame_position_slider)
    })

    shiny::observeEvent(visible(), {
      if (isTRUE(visible())) {
        shinyjs::show("frame_position_container")
      } else {
        shinyjs::hide("frame_position_container")
      }
    })

    shiny::observeEvent(
      video(),
      {
        target <- .trk_scalar_reset_target(video())
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          range = target$range,
          value = target$value
        )
      },
      ignoreNULL = FALSE
    )

    shiny::observeEvent(root$input$leftKey, {
      if (is_video_capture(video()) && current() > 1) {
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = current() - 1
        )
      }
    })

    shiny::observeEvent(root$input$rightKey, {
      if (is_video_capture(video()) && current() < n_frames(video())) {
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = current() + 1
        )
      }
    })

    shiny::observeEvent(root$input$downKey, {
      if (is_video_capture(video()) && current() >= (1 + fps(video()))) {
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = current() - fps(video())
        )
      }
    })

    shiny::observeEvent(root$input$upKey, {
      if (
        is_video_capture(video()) &&
          current() <= (n_frames(video()) - fps(video()))
      ) {
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = current() + fps(video())
        )
      }
    })

    list(
      current_frame = shiny::reactive(current()),
      set_frame = function(n) {
        shinyWidgets::updateNoUiSliderInput(
          session,
          "frame_position_slider",
          value = n
        )
      }
    )
  })
}


#' @title Open a Video Handle for Live Display
#'
#' @description This function opens a Python VideoCapture handle intended for
#'  on-demand, single-frame display reads (for example, reading whatever
#'  frame [frame_position_range_server()] or [frame_position_scalar_server()]
#'  currently reports). Use [open_bulk_video_handle()] for a handle backing a
#'  bulk sequential read operation, so that the two access patterns never
#'  share a video handle and cannot interfere with each other's read
#'  position.
#'
#' @param path A character string giving the path to a video file.
#'
#' @return A Python VideoCapture object.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [open_bulk_video_handle()]
#'
#' @export
open_display_video_handle <- function(path) {
  cv2$VideoCapture(path)
}


#' @title Open a Video Handle for a Bulk Sequential Operation
#'
#' @description This function opens a Python VideoCapture handle intended for
#'  a bulk sequential read operation (such as tracking, video export, or
#'  frame sampling) that reads frames forward without reseeking. Use
#'  [open_display_video_handle()] for a handle backing on-demand,
#'  single-frame display reads, so that the two access patterns never share a
#'  video handle and cannot interfere with each other's read position.
#'
#' @param path A character string giving the path to a video file.
#'
#' @return A Python VideoCapture object.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [open_display_video_handle()]
#'
#' @export
open_bulk_video_handle <- function(path) {
  cv2$VideoCapture(path)
}
