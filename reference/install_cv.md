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

If no Python of the requested version is found when the dedicated Python
virtual environment is created, this function installs it first. This
function does not start Python before the virtual environment exists. If
Python is already running in the current R session, restart R to use the
new virtual environment.

## See also

[`remove_cv()`](https://swarm-lab.github.io/trackRcv/reference/remove_cv.md)

## Author

Simon Garnier, <garnier@njit.edu>
