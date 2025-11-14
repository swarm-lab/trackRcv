# Reconstruct the Background of a Video

This function attempts to reconstruct the background of a video that was
filmed from a fixed point of view.

## Usage

``` r
backgrounder(
  video,
  n = 10,
  method = "median",
  prob = 0.025,
  start = NULL,
  end = NULL
)
```

## Arguments

- video:

  A Python/OpenCV VideoCapture object.

- n:

  The number of images of the video that will be used to reconstruct the
  background.

- method:

  The name of a method to reconstruct the background. There are
  currently 4 methods available: "mean" (uses the average value of each
  pixel as background), "median" (uses the median value of each pixel as
  background), "min" (uses the minimum value of each pixel as
  background), "max" (uses the maximum value of each pixel as
  background), and "quant" (uses an arbitrary quantile value of each
  pixel as background).

- prob:

  If `method = "quant"`, the quantile value to use.

- start, end:

  The start and end frames of the video to use for the background
  reconstruction. If not set, the first and last frames will be used.

## Value

A Python/Numpy array.

## Author

Simon Garnier, <garnier@njit.edu>
