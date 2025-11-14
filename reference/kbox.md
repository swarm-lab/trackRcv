# Customized Cross-Entropy Clustering

This function performs cross-entropy clustering on a data matrix. It is
based on [`cec`](https://swarm-lab.github.io/cec/reference/cec.html) but
is limited to 2D matrices and implements its own splitting process.

## Usage

``` r
kbox(
  x,
  centers = 1,
  iter.max = 10,
  split = FALSE,
  split.width = Inf,
  split.height = Inf,
  split.density = 0,
  min.size = 0,
  split.sensitivity = 0
)
```

## Arguments

- x:

  A numeric matrix with two columns.

- centers:

  Either a matrix of initial centers or the number of initial centers.

- iter.max:

  Maximum number of iterations at each clustering.

- split:

  Enables split mode. This mode discovers new clusters after initial
  clustering, by trying to split single clusters into two.

- split.width:

  The maximum authorized width of a cluster. If a cluster is wider than
  `split.width`, the function will attempt to split it in two.

- split.height:

  The maximum authorized height of a cluster. If a cluster is higher
  than `split.height`, the function will attempt to split it in two.

- split.density:

  The minimum authorized density of a cluster. If a cluster is less
  dense than `split.density`, the function will attempt to split it in
  two.

- min.size:

  The minimum authorized size (in number of items) of a cluster. If a
  cluster is smaller than `min.size`, the function will attempt to split
  it in two.

- split.sensitivity:

  The minimum amount of improvement in the cost function of the
  cross-entropy clustering for a splitting event to be considered valid.

## Value

A matrix with 6 columns: x and y coordinates of the centers of the
clusters, width, height, and angle of the covariance ellipse best
describing each cluster, and the number of element in each cluster.

## Author

Simon Garnier, <garnier@njit.edu>
