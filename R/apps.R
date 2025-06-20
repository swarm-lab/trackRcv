#' @title App Launcher
#'
#' @description This function starts an app launcher that gives the user access
#'  to all the Shiny apps provided with trackRcv. 
#'
#' @param ... Parameters to be passed to [shiny::runApp()].
#'
#' @return This function does not return anything.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#' 
#' @seealso [shiny::runApp()]
#'
#' @examples
#' \dontrun{
#' trackR()
#' }
#'
#' @export
trackR <- function(...) {
  if (cv_installed()) {
    shiny::shinyOptions(shiny.launch.browser = list(...)$launch.browser)
    shiny::runApp(paste0(find.package("trackRcv"), "/apps/launcher"), ...)
  } else {
    stop("OpenCV was not detected. Install it with `trackRcv::install_cv()`.")
  }
}
