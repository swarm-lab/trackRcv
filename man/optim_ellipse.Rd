% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ellipse.R
\name{optim_ellipse}
\alias{optim_ellipse}
\title{Fit an Ellipse}
\usage{
optim_ellipse(x, y)
}
\arguments{
\item{x, y}{Vectors of x and x positions.}
}
\value{
A vector with 5 elements: the x and y coordinated of the center of
the ellipse, the width and height of the ellipse, and the angle of the
ellipse relative to the y axis in degrees.
}
\description{
Given a set of x/y positions, this function attempts to find the
best fitting ellipse that goes through these points.
}
\author{
Simon Garnier, \email{garnier@njit.edu}
}
