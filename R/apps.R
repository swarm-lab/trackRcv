#' @export
trackR <- function(...) {
  if (cv_installed()) {
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/trackR"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}


#' @export
trackRfixer <- function(...) {
  if (cv_installed()) {
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/trackRfixer"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}


#' @export
trackRplayer <- function(...) {
  if (cv_installed()) {
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/trackRplayer"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}


