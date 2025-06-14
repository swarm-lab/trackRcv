% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ellipse.R
\name{merge_ellipses}
\alias{merge_ellipses}
\title{Merge Two Ellipses}
\usage{
merge_ellipses(ell_1, ell_2, n_points = 5, ...)
}
\arguments{
\item{ell_1, ell_2}{Numeric vector corresponding to the five parameters
defining an ellipse: centroid of the ellipse (x, y), width, height, and
angle (in degrees).}

\item{n_points}{The number of points on each ellipse used to approximate
their joint ellipsoid hull.}

\item{...}{Additional parameters to be passed to
\link[cluster]{ellipsoidhull}.}
}
\value{
A numeric vector corresponding to the five parameters defining the
joint ellipse.
}
\description{
This functions merges two ellipses by approximating their joint
ellipsoid hull, which is the ellipsoid of minimal area such that the
periphery of each ellipse lie just inside or on the boundary of the
ellipsoid.
}
\author{
Simon Garnier, \email{garnier@njit.edu}
}
