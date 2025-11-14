# Points on an Ellipse

This functions computes `npoints` regularly spaced along an ellipse.

## Usage

``` r
ellipse(x, y, width, height, angle, npoints = 100)
```

## Arguments

- x, y:

  Numeric values corresponding to the coordinates of the center of the
  ellipse.

- width, height:

  Numeric values corresponding to the width and height of the ellipse.

- angle:

  Numeric value corresponding to the angle of the ellipse relative to
  the y axis.

- npoints:

  The number of points to compute.

## Value

A matrix with two columns corresponding to the x and y coordinates of
the points.

## Author

Simon Garnier, <garnier@njit.edu>
