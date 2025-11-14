# Merge Two Ellipses

This functions merges two ellipses by approximating their joint
ellipsoid hull, which is the ellipsoid of minimal area such that the
periphery of each ellipse lie just inside or on the boundary of the
ellipsoid.

## Usage

``` r
merge_ellipses(ell_1, ell_2, n_points = 5, ...)
```

## Arguments

- ell_1, ell_2:

  Numeric vector corresponding to the five parameters defining an
  ellipse: centroid of the ellipse (x, y), width, height, and angle (in
  degrees).

- n_points:

  The number of points on each ellipse used to approximate their joint
  ellipsoid hull.

- ...:

  Additional parameters to be passed to
  [ellipsoidhull](https://rdrr.io/pkg/cluster/man/ellipsoidhull.html).

## Value

A numeric vector corresponding to the five parameters defining the joint
ellipse.

## Author

Simon Garnier, <garnier@njit.edu>
