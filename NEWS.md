# trackRcv (development version)

* The "Auto parameters" step of the `track` app no longer stops with "missing
  value where TRUE/FALSE needed". It now skips detected objects that have a
  non-finite value or a zero width or height. If no usable object is left, it
  shows a warning and leaves the parameters unchanged.
* The `fix` app now clears the displayed frame and hides the frame control
  when a video fails to load. Before, a failed load left the previous frame
  on screen.
* The `track` and `visualize` apps now clear the displayed frame and hide the
  frame control when a video fails to load, as the `fix` app does.
* Bookmark files that an earlier version of the `track` app saved no longer
  restore the analysis window. The app now saves the window with the frame
  control and ignores the old `video_range` value. An old file restores with
  the window set to the full video, from the first frame to the last frame.
* The `track` app now removes a loaded background or mask when you load a video
  of a different size, and shows one message. Before, a later step stopped with
  an OpenCV size error. A bookmark saved afterward no longer holds the removed
  background or mask.
* The `track` app no longer keeps the path of a rejected background or mask
  file. Before, a file of the wrong size left its path in the app, and a
  bookmark saved afterward restored it. The app now clears the path after a
  size mismatch. It keeps the earlier path when the file is not an image.
* New `frame_position_range_ui()` and `frame_position_range_server()` add a
  reusable frame-position control with an adjustable analysis window, for
  apps such as `track` and `visualize`. `frame_position_range_ui()` accepts
  optional `color` and `pips` parameters to reproduce a host app's own
  slider appearance.
* New `frame_position_scalar_ui()` and `frame_position_scalar_server()` add
  a reusable frame-position control with a single current frame and no
  analysis window, for apps such as `fix`. `frame_position_scalar_ui()`
  accepts optional `color` and `pips` parameters to reproduce a host app's
  own slider appearance.
* `kbox()` has a new `seed` argument. With a seed, the same data give the same
  result, and the global random number state is restored when `kbox()`
  returns. The `track` app passes the frame number as the seed, so two
  tracking runs on the same video and the same window can give the same
  result. Before, the random starting centers of `kbox()` could change the
  number of objects in some frames between runs.
* New `open_bulk_video_handle()` and `open_display_video_handle()` open
  separate Python VideoCapture handles for bulk sequential reads and
  on-demand display reads, so the two access patterns cannot interfere
  with each other's read position.

# trackRcv 0.1.1

* `install_cv()` no longer starts Python before the `trackR` virtual
  environment exists. It offers one prompt that creates the environment and
  installs the requested Python version first if it is missing.
  `library(trackRcv)` now offers the installation in an interactive session
  whenever OpenCV is missing.
