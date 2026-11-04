# trackRcv 0.1.1

* `install_cv()` no longer starts Python before the `trackR` virtual
  environment exists. It offers one prompt that creates the environment and
  installs the requested Python version first if it is missing.
  `library(trackRcv)` now offers the installation in an interactive session
  whenever OpenCV is missing.
