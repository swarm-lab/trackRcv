# Install and Update OpenCV

This function automates the installation/updating of OpenCV and all its
Python dependencies in a dedicated Python virtual environment for use
with the trackRcv apps.

## Usage

``` r
install_cv(python_version = "3.12.5")
```

## Arguments

- python_version:

  A character string indicating the version of Python you would like
  OpenCV to run on (default: "3.12.5"). Not all versions of Python will
  necessarily work on your system, but the chosen default works on most
  systems that we tested so far.

## Value

If the installation/update completes successfully, a data frame
indicating the location of the OpenCV installation and its version
number.

## Note

If the requested version of Python is not activated on your system, this
function will attempt to install it first before creating the dedicated
Python virtual environment.

## See also

[`remove_cv()`](https://swarm-lab.github.io/trackRcv/reference/remove_cv.md)

## Author

Simon Garnier, <garnier@njit.edu>
