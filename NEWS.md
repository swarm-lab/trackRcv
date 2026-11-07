# trackRcv (development version)

* The `fix` app now clears the displayed frame and hides the frame control
  when a video fails to load. Before, a failed load left the previous frame
  on screen.
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
