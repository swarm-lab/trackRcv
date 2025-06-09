#' @title Install and Update OpenCV
#'
#' @description This function automates the installation/updating of OpenCV and
#'  all its Python dependencies in a dedicated Python virtual environment for
#'  use with the \link{trackRcv} apps.
#'
#' @param python_version A character string indicating the version of Python you
#'  would like OpenCV to run on (default: "3.12.5"). Not all versions of Python
#'  will necessarily work on your system, but the chosen default works on most
#'  systems that we tested so far.
#'
#' @return If the installation/update completes successfully, a data frame
#'  indicating the location of the OpenCV installation and its version number.
#'
#' @note
#' If the requested version of Python is not activated on your system, this
#'  function will attempt to install it first before creating the dedicated
#'  Python virtual environment.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [remove_cv()]
#'
#' @export
install_cv <- function(python_version = "3.12.5") {
  if (reticulate::virtualenv_exists("trackR")) {
    reticulate::use_virtualenv("trackR", required = TRUE)
  } else if (reticulate::virtualenv_exists("r-reticulate")) {
    reticulate::use_virtualenv("r-reticulate", required = TRUE)
  }

  reticulate::py_available(TRUE)

  if (is.null(reticulate::py_discover_config())) {
    py_installed <- FALSE
  } else if (
    !grepl(python_version, reticulate::py_discover_config()$version_string)
  ) {
    py_installed <- FALSE
  } else {
    py_installed <- TRUE
  }

  if (!py_installed) {
    answer <- utils::askYesNo(
      paste0(
        "\n------------------------------------------------------------",
        "\n",
        "\nThe Python version found on this system is not the requested one.",
        "\nPython ",
        python_version,
        " will be installed.",
        "\nWould you like to continue?",
        "\n",
        "\n------------------------------------------------------------",
        "\n"
      )
    )

    if (is.na(answer)) {
      answer <- FALSE
    }

    if (answer) {
      reticulate::install_python(version = python_version)
    } else {
      warning(
        "\nContinuing installation of OpenCV with a non-requested version of Python.\n"
      )
    }
  }

  if (!reticulate::virtualenv_exists("trackR")) {
    answer <- utils::askYesNo(
      paste0(
        "\n------------------------------------------------------------",
        "\n",
        "\nNo trackR environment was found on this system.",
        "\nIt will be created with all the necessary packages.",
        "\nWould you like to continue?",
        "\n",
        "\n------------------------------------------------------------",
        "\n"
      )
    )

    if (is.na(answer)) {
      answer <- FALSE
    }

    if (answer) {
      reticulate::virtualenv_create(
        envname = "trackR",
        version = python_version,
      )
      reticulate::virtualenv_install(
        envname = "trackR",
        packages = c("opencv-python")
      )
    } else {
      stop("\nOpenCV was not installed on this system.\n")
    }
  } else if (!cv_installed()) {
    answer <- utils::askYesNo(
      paste0(
        "\n------------------------------------------------------------",
        "\n",
        "\nNo OpenCV installation was found on this system.",
        "\nIt will be installed with all the necessary dependencies.",
        "\nWould you like to continue?",
        "\n",
        "\n------------------------------------------------------------",
        "\n"
      )
    )

    if (is.na(answer)) {
      answer <- FALSE
    }

    if (answer) {
      reticulate::virtualenv_install(
        envname = "trackR",
        packages = c("opencv-python")
      )
    } else {
      stop("\nOpenCV was not installed on this system.\n")
    }
  } else {
    answer <- utils::askYesNo(
      paste0(
        "\n------------------------------------------------------------",
        "\n",
        "\nOpenCV is already installed on this system.",
        "\nWould you like to try updating it?",
        "\n",
        "\n------------------------------------------------------------",
        "\n"
      )
    )

    if (is.na(answer)) {
      answer <- FALSE
    }

    if (answer) {
      reticulate::virtualenv_install(
        envname = "trackR",
        packages = c(
          "pip"
        ),
        pip_options = "--upgrade"
      )
      reticulate::virtualenv_install(
        envname = "trackR",
        packages = c("opencv-python"),
        pip_options = "--upgrade"
      )
    }
  }

  data.frame(
    install_path = tryCatch(
      normalizePath(
        paste0(reticulate::virtualenv_root(), "/trackR"),
        mustWork = TRUE
      ),
      error = function(e) NA
    ),
    version = cv_version()
  )
}


#' @title Remove OpenCV
#'
#' @description This function automates the removal of OpenCV and all its Python
#'  dependencies from your system.
#'
#' @return Nothing.
#'
#' @note
#' The function will only remove the dedicated Python virtual environment from
#'  your system. If Python was installed during the execution of
#'  [install_cv()], it will not be removed.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [install_cv()]
#'
#' @export
remove_cv <- function() {
  unlink(
    normalizePath(
      paste0(reticulate::virtualenv_root(), "/trackR"),
      mustWork = TRUE
    ),
    recursive = TRUE
  )
}


#' @title Detect OpenCV Installation
#'
#' @description This function detects whether OpenCV is correctly installed on
#'  the system.
#'
#' @return A logical indicating the presence or absence of OpenCV.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [install_cv()]
#'
#' @export
cv_installed <- function() {
  if (reticulate::virtualenv_exists("trackR")) {
    pkgs <- reticulate::py_list_packages("trackR")
    any(grepl("opencv", pkgs$package))
  } else {
    FALSE
  }
}


#' @title Detect OpenCV Version
#'
#' @description This function detects the version of OpenCV installed on the
#'  system.
#'
#' @return A character string. NA indicates that OpenCV is not installed on the
#'  system.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso [install_cv()]
#'
#' @export
cv_version <- function() {
  if (reticulate::virtualenv_exists("trackR")) {
    pkgs <- reticulate::py_list_packages("trackR")
    pkgs$version[grepl("opencv", pkgs$package)]
  } else {
    NA
  }
}


#' @title Test for a Python VideoCapture Object
#'
#' @description This function tests whether an object is a Python VideoCapture
#'  object.
#'
#' @param x Any R object.
#'
#' @return A logical indicating whether the object is a Python VideoCapture
#'  object (TRUE) or not (FALSE).
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
is_video_capture <- function(x) {
  inherits(x, c("cv2.VideoCapture", "python.builtin.object"))
}


#' @title Number of Frames in a Python VideoCapture Object
#'
#' @description This function returns the number of frames present in a Python
#'  VideoCapture object.
#'
#' @param x A Python VideoCapture object.
#'
#' @return A numeric value.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
n_frames <- function(x) {
  if (is_video_capture(x)) {
    reticulate::py_to_r(x$get(cv2$CAP_PROP_FRAME_COUNT))
  } else {
    NA
  }
}


#' @title Framerate of a Python VideoCapture Object
#'
#' @description This function returns the framerate of a Python VideoCapture
#'  object.
#'
#' @param x A Python VideoCapture object.
#'
#' @return A numeric value.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
fps <- function(x) {
  if (is_video_capture(x)) {
    reticulate::py_to_r(x$get(cv2$CAP_PROP_FPS))
  } else {
    NA
  }
}


#' @title Read Specific Frame in a Python VideoCapture Object
#'
#' @description This function reads a specific frame of a Python VideoCapture
#'  object and returns it as Numpy array.
#'
#' @param x A Python VideoCapture object.
#'
#' @param i The 1-indexed frame to be read.
#'
#' @return A Numpy array.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
read_frame <- function(x, i) {
  if (is_video_capture(x)) {
    x$set(cv2$CAP_PROP_POS_FRAMES, i - 1)
    x$read()[1]
  } else {
    stop("This is not a Python/OpenCV VideoCapture object.")
  }
}


#' @title Test for a Numpy Array
#'
#' @description This function tests whether an object is a Numpy array.
#'
#' @param x Any R object.
#'
#' @return A logical indicating whether the object is a Numpy array (TRUE) or
#'  not (FALSE).
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
is_image <- function(x) {
  all(
    inherits(x, c("numpy.ndarray", "python.builtin.object"), which = TRUE) != 0
  )
}


#' @title Number of Rows in a Numpy Array
#'
#' @description This function returns the number of rows present in a Numpy
#'  array.
#'
#' @param x A Numpy array.
#'
#' @return A numeric value.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
n_row <- function(x) {
  if (is_image(x)) {
    reticulate::py_to_r(x$shape[0])
  } else if (is_video_capture(x)) {
    reticulate::py_to_r(x$get(cv2$CAP_PROP_FRAME_HEIGHT))
  } else {
    NULL
  }
}


#' @title Number of Columns in a Numpy Array
#'
#' @description This function returns the number of columns present in a Numpy
#'  array.
#'
#' @param x A Numpy array.
#'
#' @return A numeric value.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
n_col <- function(x) {
  if (is_image(x)) {
    reticulate::py_to_r(x$shape[1])
  } else if (is_video_capture(x)) {
    reticulate::py_to_r(x$get(cv2$CAP_PROP_FRAME_WIDTH))
  } else {
    NULL
  }
}


#' @title Color to BGR Conversion
#'
#' @description R color to BRG (blue/green/red) conversion.
#'
#' @param col Vector of any of the three kinds of R color specifications, i.e.,
#'  either a color name (as listed by \code{\link{colors}}()), a hexadecimal
#'  string of the form "\code{#rrggbb}" or "\code{#rrggbbaa}" (see
#'  \code{\link{rgb}}), or a positive integer \code{i} meaning
#'  \code{\link{palette}()[i]}.
#'
#' @param alpha Logical value indicating whether the alpha channel (opacity)
#'  values should be returned.
#'
#' @details \code{\link{NA}} (as integer or character) and "NA" mean transparent.
#'
#' Values of \code{col} not of one of these types are coerced: real vectors are
#'  coerced to integer and other types to character. (factors are coerced to
#'  character: in all other cases the class is ignored when doing the coercion.)
#'
#' Zero and negative values of \code{col} are an error.
#'
#' @return An integer matrix with three or four (for \code{alpha = TRUE}) rows
#'  and number of columns the length of \code{col}. If col has names these are
#'  used as the column names of the return value.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @seealso \code{\link{col2rgb}}, \code{\link{rgb}}, \code{\link{palette}}
#'
#' @export
col2bgr <- function(col, alpha = FALSE) {
  if (alpha) {
    grDevices::col2rgb(col, alpha)[c(3:1, 4), , drop = FALSE]
  } else {
    grDevices::col2rgb(col, alpha)[3:1, , drop = FALSE]
  }
}


#' @title Codec Name to FOURCC Code
#'
#' @description \code{fourcc} translates the 4-character name of a video codec
#'  into its corresponding \href{https://www.fourcc.org/codecs.php}{FOURCC}
#'  code.
#'
#' @param x A 4-element character chain corresponding to the name of a valid
#'  video codec. A list of valid codec names can be found at this archived
#'  page of the fourcc site
#'  \href{https://www.fourcc.org/codecs.php}{https://www.fourcc.org/codecs.php}.
#'
#' @return An integer value corresponding to the FOURCC code of the video codec.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
fourcc <- function(str) {
  chars <- unlist(strsplit(str, split = ""))
  reticulate::py_to_r(cv2$VideoWriter_fourcc(
    chars[1],
    chars[2],
    chars[3],
    chars[4]
  ))
}
