# Remove OpenCV

This function automates the removal of OpenCV and all its Python
dependencies from your system.

## Usage

``` r
remove_cv()
```

## Value

Nothing.

## Note

The function will only remove the dedicated Python virtual environment
from your system. If Python was installed during the execution of
[`install_cv()`](https://swarm-lab.github.io/trackRcv/reference/install_cv.md),
it will not be removed.

## See also

[`install_cv()`](https://swarm-lab.github.io/trackRcv/reference/install_cv.md)

## Author

Simon Garnier, <garnier@njit.edu>
