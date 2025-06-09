#' @importFrom autothresholdr auto_thresh
#' @importFrom data.table fread
#' @importFrom mvoutlier pcout
#' @importFrom pals alphabet
#' @importFrom pracma inpolygon
#' @importFrom shinyFiles parseFilePaths
#' @importFrom shinyalert shinyalert
#' @importFrom shinyWidgets verticalTabsetPanel
#' @importFrom shinyjs useShinyjs
#' @importFrom stringr str_locate_all

local <- new.env()

.onLoad <- function(libname, pkgname) {
  reticulate::configure_environment(pkgname)

  cv2 <- reticulate::import("cv2", convert = FALSE, delay_load = TRUE)
  assign("cv2", value = cv2, envir = parent.env(local))

  np <- reticulate::import("numpy", convert = FALSE, delay_load = TRUE)
  assign("np", value = np, envir = parent.env(local))

  base64 <- reticulate::import("base64", convert = FALSE, delay_load = TRUE)
  assign("base64", value = base64, envir = parent.env(local))
}

.onAttach <- function(lib, pkg) {
  if (!cv_installed()) {
    if (interactive()) {
      msg <- install_cv()
      print.table(msg)
    }
  }
}