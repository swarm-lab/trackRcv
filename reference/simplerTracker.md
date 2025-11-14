# A Simple Tracker

Given a set of current x/y positions, this function attempts to find
which trajectory they belong to in a set of past tracked positions using
the Hungarian method.

## Usage

``` r
simplerTracker(current, past, maxDist = 10)
```

## Arguments

- current:

  A data frame with at least 4 columns: x, y, frame, and track.

- past:

  A data frame with at least 4 columns: x, y, frame, and track.

- maxDist:

  The maximum distance between two successive positions belonging to the
  same trajectory.

## Value

A data frame with at least 4 columns: x, y, frame, and track.

## Author

Simon Garnier, <garnier@njit.edu>
