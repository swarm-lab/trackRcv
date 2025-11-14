# Fit an Ellipse

Given a set of x/y positions, this function attempts to find the best
fitting ellipse that goes through these points.

## Usage

``` r
optim_ellipse(x, y)
```

## Arguments

- x, y:

  Vectors of x and x positions.

## Value

A vector with 5 elements: the x and y coordinated of the center of the
ellipse, the width and height of the ellipse, and the angle of the
ellipse relative to the y axis in degrees.

## Author

Simon Garnier, <garnier@njit.edu>
