#' @title Video Tracking App
#'
#' @description A video tracking software with a Shiny-based GUI.
#'
#' @param ... Arguments passed to \link[shiny]{runApp}.
#'
#' @return This function does not return anything. A file is saved if the
#'  tracking is successfully completed.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
trackR <- function(...) {
  if (cv_installed()) {
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/trackR"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}


#' @title Fix Tracking Errors
#'
#' @description Shiny-based GUI to fix a posteriori common tracking errors, such
#'  as removing unwanted tracks, fixing swapped track IDs and reconnecting
#'  tracks.
#'
#' @param ... Arguments passed to \link[shiny]{runApp}.
#'
#' @return This function does not return anything. A file is saved if the save
#'  button is used in the app.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
trackFixer <- function(...) {
  if (cv_installed()) {
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/trackFixer"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}


#' @title Display and Export Video with Track Overlay
#'
#' @description Shiny-based GUI to display and export a video with tracks
#'  overlaid on top.
#'
#' @param ... Arguments passed to \link[shiny]{runApp}.
#'
#' @return This function does not return anything. A file is saved if the export
#'  button is used in the app.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
trackPlayer <- function(...) {
  if (cv_installed()) {
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/trackPlayer"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}
