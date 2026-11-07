.trk_has_cv <- tryCatch(
  {
    reticulate::use_virtualenv("trackR", required = TRUE)
    trackRcv::cv_installed()
  },
  error = function(e) FALSE
)
