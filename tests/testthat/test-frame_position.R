video_path <- system.file("termites", "video.mp4", package = "trackRcv")

# Skips the calling test when the video fixture is missing (defensive:
# inst/termites is a normal, shipped package resource, so this should not
# trigger in a correctly built package) or when OpenCV (the `trackR`
# virtualenv) is unavailable, e.g. in CI environments that provision no
# Python/OpenCV toolchain.
skip_unless_fixture <- function() {
  testthat::skip_if(
    !nzchar(video_path) || !file.exists(video_path),
    "video fixture unavailable"
  )
  testthat::skip_if_not(.trk_has_cv, "OpenCV (trackR virtualenv) unavailable")
}

# Opens the shared test video via the display handle.
test_video <- function() {
  skip_unless_fixture()
  open_display_video_handle(video_path)
}

# Same as test_video(), but through the bulk-sequential acquisition path.
test_bulk_video <- function() {
  skip_unless_fixture()
  open_bulk_video_handle(video_path)
}

# A stub app server hosting one control, exposing the reactives that drive it
# and its returned handle through session$userData so tests can read and set
# them.
range_app <- function(video_val = NULL, visible_val = TRUE) {
  function(input, output, session) {
    video_rv <- shiny::reactiveVal(video_val)
    visible_rv <- shiny::reactiveVal(visible_val)
    session$userData$video <- video_rv
    session$userData$visible <- visible_rv
    session$userData$handle <- frame_position_range_server(
      "fp",
      video_rv,
      visible_rv
    )
  }
}

scalar_app <- function(video_val = NULL, visible_val = TRUE) {
  function(input, output, session) {
    video_rv <- shiny::reactiveVal(video_val)
    visible_rv <- shiny::reactiveVal(visible_val)
    session$userData$video <- video_rv
    session$userData$visible <- visible_rv
    session$userData$handle <- frame_position_scalar_server(
      "fp",
      video_rv,
      visible_rv
    )
  }
}

# Mocks shinyWidgets::updateNoUiSliderInput for the current test: every call
# is recorded (as a list with `range` and `value`) in the returned
# environment's `log`, without taking effect on its own (a mock session has
# no real control to apply it).
mock_slider_push <- function(env = parent.frame()) {
  calls <- new.env()
  calls$log <- list()
  testthat::local_mocked_bindings(
    updateNoUiSliderInput = function(
      session,
      inputId,
      value = NULL,
      range = NULL,
      ...
    ) {
      calls$log[[length(calls$log) + 1]] <- list(range = range, value = value)
    },
    .package = "shinyWidgets",
    .env = env
  )
  calls
}

# Sets the module's own slider input directly, as a real control does once
# it renders with a given value (used to seed a starting state).
echo_slider <- function(session, value) {
  session$setInputs(`fp-frame_position_slider` = value)
}

# Applies the most recently recorded push (see mock_slider_push()) as the
# module's own slider input, as a real control does once it re-renders with
# a requested value.
apply_last_push <- function(session, calls) {
  echo_slider(session, calls$log[[length(calls$log)]]$value)
}


test_that(".trk_step_clamp steps normally within bounds", {
  expect_equal(.trk_step_clamp(5, 1, 0, 10), 6)
})

test_that(".trk_step_clamp clamps at the upper bound", {
  expect_equal(.trk_step_clamp(9, 5, 0, 10), 10)
})

test_that(".trk_step_clamp clamps at the lower bound", {
  expect_equal(.trk_step_clamp(2, -5, 0, 10), 0)
})


test_that("range current_frame() and frame_range() mirror the control only", {
  shiny::testServer(range_app(), {
    echo_slider(session, c(3, 5, 12))
    expect_equal(session$userData$handle$current_frame(), 5)
    expect_equal(session$userData$handle$frame_range(), c(3, 12))
  })
})

test_that("range set_frame() only pushes to the control, never writes state", {
  calls <- mock_slider_push()

  shiny::testServer(range_app(), {
    echo_slider(session, c(1, 5, 10))
    session$userData$handle$set_frame(9999)

    # push-only: the raw, unclamped value is forwarded to the control.
    expect_equal(calls$log[[length(calls$log)]]$value, c(1, 9999, 10))
    # no direct state write: the accessor still reports the pre-push value.
    expect_equal(session$userData$handle$current_frame(), 5)

    # the control applies its own clamp and reports the clamped value back.
    echo_slider(session, c(1, 10, 10))
    expect_equal(session$userData$handle$current_frame(), 10)
  })
})

test_that("range pushes c(1, n_frames) on successful video load", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(range_app(), {
    session$userData$video(video)
    session$flushReact()
  })

  last <- calls$log[[length(calls$log)]]
  expect_equal(last$range, c(1, n_frames(video)))
  expect_equal(last$value, c(1, 1, n_frames(video)))
})

test_that("range pushes c(0, 0) on failed/absent video load", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(range_app(video_val = video), {
    session$userData$video(NULL)
    session$flushReact()
  })

  last <- calls$log[[length(calls$log)]]
  expect_equal(last$range, c(0, 0))
  expect_equal(last$value, c(0, 0, 0))
})

test_that("range single-frame step at the window boundary has no effect", {
  calls <- mock_slider_push()

  shiny::testServer(range_app(), {
    session$flushReact()
    baseline <- length(calls$log)
    echo_slider(session, c(5, 5, 20))
    session$setInputs(leftKey = 1)
    expect_equal(length(calls$log), baseline)
    expect_equal(session$userData$handle$current_frame(), 5)

    echo_slider(session, c(5, 20, 20))
    session$setInputs(rightKey = 1)
    expect_equal(length(calls$log), baseline)
    expect_equal(session$userData$handle$current_frame(), 20)
  })
})

test_that("range one-second step clamps to the window boundary, not the video's", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(range_app(video_val = video), {
    echo_slider(session, c(5, 6, 20))
    session$setInputs(downKey = 1)
    apply_last_push(session, calls)
    expect_equal(session$userData$handle$current_frame(), 5)

    echo_slider(session, c(5, 19, 20))
    session$setInputs(upKey = 1)
    apply_last_push(session, calls)
    expect_equal(session$userData$handle$current_frame(), 20)
  })
})

test_that(".trk_range_reset_target resets to the full range without a restore", {
  video <- test_video()
  target <- .trk_range_reset_target(video, NULL)
  expect_equal(target$range, c(1, n_frames(video)))
  expect_equal(target$value, c(1, 1, n_frames(video)))
})

test_that(".trk_range_reset_target applies a restored range instead of the full range", {
  video <- test_video()
  target <- .trk_range_reset_target(video, c(100, 400))
  expect_equal(target$range, c(1, n_frames(video)))
  expect_equal(target$value, c(100, 100, 400))
})

test_that(".trk_range_reset_target zero-resets on a failed/absent video load", {
  target <- .trk_range_reset_target(NULL, c(100, 400))
  expect_equal(target$range, c(0, 0))
  expect_equal(target$value, c(0, 0, 0))
})

# A MockShinySession with onRestore patched to record registered callbacks,
# so a session restore can be simulated by invoking them directly (the
# stock MockShinySession treats onRestore as a no-op).
restorable_session <- function() {
  session <- shiny:::MockShinySession$new()
  restore_log <- new.env()
  restore_log$fns <- list()
  session$onRestore <- function(fun) {
    restore_log$fns[[length(restore_log$fns) + 1]] <- fun
    invisible()
  }
  session$userData$restore_log <- restore_log
  session
}

simulate_restore <- function(session, frame_range) {
  for (fn in session$userData$restore_log$fns) {
    fn(list(values = list(frame_range = frame_range)))
  }
}

test_that("a restored session applies the saved analysis window on video load", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(range_app(), session = restorable_session(), {
    simulate_restore(session, c(100, 400))
    session$userData$video(video)
    session$flushReact()
  })

  last <- calls$log[[length(calls$log)]]
  expect_equal(last$range, c(1, n_frames(video)))
  expect_equal(last$value, c(100, 100, 400))
})

test_that("a restore survives a NULL-video flush before the video actually loads", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(range_app(), session = restorable_session(), {
    simulate_restore(session, c(100, 400))
    # host has not reopened the file yet: video() is still NULL at this flush,
    # mirroring real restore timing where onRestore fires before the host's
    # own (asynchronous) video load.
    session$flushReact()
    session$userData$video(video)
    session$flushReact()
  })

  last <- calls$log[[length(calls$log)]]
  expect_equal(last$range, c(1, n_frames(video)))
  expect_equal(last$value, c(100, 100, 400))
})

test_that("a video load outside of a restore still resets to the full range", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(range_app(), session = restorable_session(), {
    # no simulate_restore() call: this is a plain load, not a restore.
    session$userData$video(video)
    session$flushReact()
  })

  last <- calls$log[[length(calls$log)]]
  expect_equal(last$range, c(1, n_frames(video)))
  expect_equal(last$value, c(1, 1, n_frames(video)))
})


test_that("scalar exposes no frame_range accessor", {
  shiny::testServer(scalar_app(), {
    expect_false("frame_range" %in% names(session$userData$handle))
  })
})

test_that("scalar current_frame() mirrors the control only", {
  shiny::testServer(scalar_app(), {
    echo_slider(session, 7)
    expect_equal(session$userData$handle$current_frame(), 7)
  })
})

test_that(".trk_scalar_reset_target resets to 1 on success, 0 on failure", {
  video <- test_video()
  expect_equal(.trk_scalar_reset_target(video)$value, 1)
  expect_equal(.trk_scalar_reset_target(video)$range, c(1, n_frames(video)))
  expect_equal(.trk_scalar_reset_target(NULL)$value, 0)
  expect_equal(.trk_scalar_reset_target(NULL)$range, c(0, 0))
})

test_that("scalar single-frame step at the video boundary has no effect", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(scalar_app(video_val = video), {
    session$flushReact()
    baseline <- length(calls$log)
    echo_slider(session, 1)
    session$setInputs(leftKey = 1)
    expect_equal(length(calls$log), baseline)
    expect_equal(session$userData$handle$current_frame(), 1)

    echo_slider(session, n_frames(video))
    session$setInputs(rightKey = 1)
    expect_equal(length(calls$log), baseline)
    expect_equal(session$userData$handle$current_frame(), n_frames(video))
  })
})

test_that("scalar one-second step at the video boundary also has no effect", {
  calls <- mock_slider_push()
  video <- test_video()

  shiny::testServer(scalar_app(video_val = video), {
    session$flushReact()
    baseline <- length(calls$log)
    echo_slider(session, 1)
    session$setInputs(downKey = 1)
    expect_equal(length(calls$log), baseline)
    expect_equal(session$userData$handle$current_frame(), 1)

    echo_slider(session, n_frames(video))
    session$setInputs(upKey = 1)
    expect_equal(length(calls$log), baseline)
    expect_equal(session$userData$handle$current_frame(), n_frames(video))
  })
})


test_that("open_display_video_handle and open_bulk_video_handle are isolated", {
  display <- test_video()
  bulk <- test_bulk_video()

  bulk$read()
  read_frame(display, 50)
  next_bulk_pos <- reticulate::py_to_r(bulk$get(cv2$CAP_PROP_POS_FRAMES))

  expect_equal(next_bulk_pos, 1)
})


test_that("range control is shown when the host's visibility condition is true", {
  calls <- list()
  testthat::local_mocked_bindings(
    show = function(id) {
      calls[[length(calls) + 1]] <<- list(action = "show", id = id)
    },
    hide = function(id) {
      calls[[length(calls) + 1]] <<- list(action = "hide", id = id)
    },
    .package = "shinyjs"
  )

  shiny::testServer(range_app(visible_val = FALSE), {
    session$userData$visible(TRUE)
    session$flushReact()
  })

  last <- calls[[length(calls)]]
  expect_equal(last$action, "show")
  # the id must be plain (not manually namespaced): shinyjs auto-namespaces
  # ids itself when called from inside a module.
  expect_equal(last$id, "frame_position_container")
})

test_that("range control is hidden when the host's visibility condition is false", {
  calls <- list()
  testthat::local_mocked_bindings(
    show = function(id) {
      calls[[length(calls) + 1]] <<- list(action = "show", id = id)
    },
    hide = function(id) {
      calls[[length(calls) + 1]] <<- list(action = "hide", id = id)
    },
    .package = "shinyjs"
  )

  shiny::testServer(range_app(visible_val = TRUE), {
    session$userData$visible(FALSE)
    session$flushReact()
  })

  last <- calls[[length(calls)]]
  expect_equal(last$action, "hide")
  expect_equal(last$id, "frame_position_container")
})


test_that("frame_position_range_ui with no appearance args renders the plain default", {
  html <- as.character(frame_position_range_ui("fp"))
  expect_no_match(html, "noUi-connect", fixed = TRUE)
  expect_no_match(html, "#2b4e8d", fixed = TRUE)
})

test_that("frame_position_range_ui with color renders that connect-bar color", {
  html <- as.character(frame_position_range_ui("fp", color = "#2b4e8d"))
  expect_match(html, "noUi-connect", fixed = TRUE)
  expect_match(html, "#2b4e8d", fixed = TRUE)
})

test_that("frame_position_range_ui with pips renders that pip configuration", {
  html <- as.character(
    frame_position_range_ui(
      "fp",
      pips = list(mode = "count", values = 5, density = 0)
    )
  )
  expect_match(html, "count", fixed = TRUE)
})

test_that("frame_position_scalar_ui with no appearance args renders the plain default", {
  html <- as.character(frame_position_scalar_ui("fp"))
  expect_no_match(html, "noUi-connect", fixed = TRUE)
  expect_no_match(html, "#2b4e8d", fixed = TRUE)
})

test_that("frame_position_scalar_ui with color renders that connect-bar color", {
  html <- as.character(frame_position_scalar_ui("fp", color = "#2b4e8d"))
  expect_match(html, "noUi-connect", fixed = TRUE)
  expect_match(html, "#2b4e8d", fixed = TRUE)
})

test_that("frame_position_scalar_ui with pips renders that pip configuration", {
  html <- as.character(
    frame_position_scalar_ui(
      "fp",
      pips = list(mode = "count", values = 5, density = 0)
    )
  )
  expect_match(html, "count", fixed = TRUE)
})
