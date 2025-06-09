#' @title Fit an Ellipse
#'
#' @description Given a set of x/y positions, this function attempts to find the
#'  best fitting ellipse that goes through these points.
#'
#' @param x,y Vectors of x and x positions.
#'
#' @return A vector with 5 elements: the x and y coordinated of the center of
#'  the ellipse, the width and height of the ellipse, and the angle of the
#'  ellipse relative to the y axis in degrees.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
optim_ellipse <- function(x, y) {
  md <- sqrt((max(x) - min(x))^2 + (max(y) - min(y))^2)
  start <- c(mean(x), mean(y), md, md, 0)

  opt <- stats::optim(
    start,
    function(par) {
      sum((.dist2ellipse(x, y, par[1], par[2], par[3], par[4], par[5]) - 1)^2)
    },
    method = "L-BFGS-B",
    lower = c(min(x), min(y), -Inf, -Inf, -pi),
    upper = c(max(x), max(y), Inf, Inf, pi)
  )

  out <- opt$par
  out[5] <- 180 * out[5] / pi
  out
}


#' @title Points on an Ellipse
#'
#' @description This functions computes \code{npoints} regularly spaced along an
#'  ellipse.
#'
#' @param x,y Numeric values corresponding to the coordinates of the center of
#'  the ellipse.
#'
#' @param width,height Numeric values corresponding to the width and height of
#'  the ellipse.
#'
#' @param angle Numeric value corresponding to the angle of the ellipse relative
#'  to the y axis.
#'
#' @param npoints The number of points to compute.
#'
#' @return A matrix with two columns corresponding to the x and y coordinates of
#'  the points.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
ellipse <- function(x, y, width, height, angle, npoints = 100) {
  angle <- angle * pi / 180
  segment <- c(0, 2 * pi)
  z <- seq(segment[1], segment[2], length = npoints + 1)
  xx <- (width / 2) * cos(z)
  yy <- (height / 2) * sin(z)
  alpha <- .xyangle(xx, yy, directed = TRUE)
  rad <- sqrt(xx^2 + yy^2)
  cbind(x = rad * cos(alpha + angle) + x, y = rad * sin(alpha + angle) + y)
}


#' @title Merge Two Ellipses
#'
#' @description This functions merges two ellipses by approximating their joint
#'  ellipsoid hull, which is the ellipsoid of minimal area such that the 
#'  periphery of each ellipse lie just inside or on the boundary of the 
#'  ellipsoid.
#'
#' @param ell_1,ell_2 Numeric vector corresponding to the five parameters 
#'  defining an ellipse: centroid of the ellipse (x, y), width, height, and 
#'  angle (in degrees).
#'
#' @param n_points The number of points on each ellipse used to approximate 
#'  their joint ellipsoid hull. 
#' 
#' @param ... Additional parameters to be passed to 
#'  \link[cluster]{ellipsoidhull}. 
#'
#' @return A numeric vector corresponding to the five parameters defining the 
#'  joint ellipse. 
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
merge_ellipses <- function(ell_1, ell_2, n_points = 5, ...) {
  pts <- rbind(
    ellipse(ell_1[1], ell_1[2], ell_1[3], ell_1[4], ell_1[5], n_points),
    ellipse(ell_2[1], ell_2[2], ell_2[3], ell_2[4], ell_2[5], n_points)
  )
  hull <- cluster::ellipsoidhull(pts, ...)
  .cov2shape(hull$cov, hull$loc)
}
