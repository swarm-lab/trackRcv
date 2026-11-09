#' @title A Simple Tracker
#'
#' @description Given a set of current x/y positions, this function attempts to
#'  find which trajectory they belong to in a set of past tracked positions
#'  using the Hungarian method.
#'
#' @param current A data frame with at least 4 columns: x, y, frame, and track.
#'
#' @param past A data frame with at least 4 columns: x, y, frame, and track.
#'
#' @param maxDist The maximum distance between two successive positions
#'  belonging to the same trajectory.
#'
#' @return A data frame with at least 4 columns: x, y, frame, and track.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
simplerTracker <- function(current, past, maxDist = 10) {
  if (nrow(past) == 0) {
    current$track <- NA
    return(current)
  }

  frames <- seq(max(past$frame), min(past$frame), -1)

  for (f in frames) {
    if (nrow(past) > 0 & sum(is.na(current$track)) > 0) {
      tmp <- past[past$frame == f, ]

      if (nrow(tmp) > 0) {
        # mat <- abs(.pdiff(current$x, tmp$x)) + abs(.pdiff(current$y, tmp$y))
        mat <- sqrt(.pdiff(current$x, tmp$x)^2 + .pdiff(current$y, tmp$y)^2)
        mat[!is.na(current$track), ] <- max(mat) * 2

        if (nrow(mat) > ncol(mat)) {
          h <- rep(NA, nrow(mat))
          h[as.vector(clue::solve_LSAP(t(sqrt(mat))))] <- seq(1, ncol(mat))
        } else {
          h <- as.vector(clue::solve_LSAP(sqrt(mat)))
        }

        valid <- mat[(h - 1) * nrow(mat) + 1:nrow(mat)] <=
          (maxDist * (current$frame[1] - f))

        h[!valid] <- NA
        current$track[!is.na(h)] <- tmp$track[h[!is.na(h)]]

        past <- past[past$frame != f, ]
        past <- past[!(past$track %in% tmp$track[h]), ]
      }
    } else {
      break()
    }
  }

  current
}


#' @title Customized Cross-Entropy Clustering
#'
#' @description This function performs cross-entropy clustering on a data matrix.
#'  It is based on \code{\link[CEC]{cec}} but is limited to 2D matrices and
#'  implements its own splitting process.
#'
#' @param x A numeric matrix with either two columns (x, y coordinates,
#'  unweighted) or three columns (x, y coordinates and a non-negative
#'  per-observation weight). When a weight column is supplied, cluster
#'  means, covariances, and the internal fitting-time cardinality guard
#'  become weight-aware (see \code{\link[CEC]{cec}}'s \code{weights}
#'  argument); observations with a larger weight pull the fit more
#'  strongly than observations with a smaller weight.
#'
#' @param centers Either a matrix of initial centers or the number of initial
#'  centers.
#'
#' @param iter.max Maximum number of iterations at each clustering.
#'
#' @param split Enables split mode. This mode discovers new clusters after
#'  initial clustering, by trying to split single clusters into two.
#'
#' @param split.width The maximum authorized width of a cluster. If a cluster is
#'  wider than \code{split.width}, the function will attempt to split it in two.
#'
#' @param split.height The maximum authorized height of a cluster. If a cluster
#'  is higher than \code{split.height}, the function will attempt to split it in
#'  two.
#'
#' @param split.density The minimum authorized density of a cluster. If a
#'  cluster is less dense than \code{split.density}, the function will attempt
#'  to split it in two.
#'
#' @param min.size The minimum authorized size (in number of items) of a
#'  final cluster. Clusters smaller than \code{min.size} after all splitting
#'  is complete are dropped from the returned result. \code{min.size} is
#'  also used to derive the (weight-aware) cardinality guard applied during
#'  fitting, scaled to each internal clustering call's own weight/point
#'  totals.
#'
#' @param split.sensitivity The minimum amount of improvement in the cost
#'  function of the cross-entropy clustering for a splitting event to be
#'  considered valid.
#'
#' @param seed \code{NULL} or one finite number. If it is a number,
#'  \code{kbox()} calls \code{\link[base]{set.seed}} with it before it
#'  clusters, and restores the previous state of the random number generator
#'  when it returns. The same \code{seed} and the same data then give the same
#'  result. If it is \code{NULL}, \code{kbox()} uses the current state of the
#'  random number generator, and repeated calls can give different results.
#'
#' @return A matrix with 6 columns: x and y coordinates of the centers of the
#'  clusters, width, height, and angle of the covariance ellipse best describing
#'  each cluster, and the number of element in each cluster. \code{NULL} if
#'  clustering fails or no cluster meets \code{min.size}.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @export
kbox <- function(
  x,
  centers = 1,
  iter.max = 10,
  split = FALSE,
  split.width = Inf,
  split.height = Inf,
  split.density = 0,
  min.size = 0,
  split.sensitivity = 0,
  seed = NULL
) {
  if (!is.null(seed)) {
    if (!is.numeric(seed) || length(seed) != 1 || !is.finite(seed)) {
      stop("`seed` must be NULL or a single finite number.", call. = FALSE)
    }

    genv <- globalenv()
    had_seed <- exists(".Random.seed", envir = genv, inherits = FALSE)
    if (had_seed) {
      old_seed <- get(".Random.seed", envir = genv, inherits = FALSE)
    }

    on.exit(
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = genv)
      } else if (exists(".Random.seed", envir = genv, inherits = FALSE)) {
        rm(".Random.seed", envir = genv)
      },
      add = TRUE
    )

    set.seed(seed)
  }

  if (!is.matrix(x)) {
    x <- as.matrix(x)
  }

  if (ncol(x) == 3) {
    weights <- x[, 3]
    x <- x[, 1:2]
  } else {
    weights <- NULL
  }

  card_min <- function(x, weights) {
    max(sum(weights) * (min.size / nrow(x)), ncol(x) + 1)
  }

  if (is.null(dim(centers))) {
    cl <- tryCatch(
      CEC::cec(
        x,
        centers,
        iter.max = iter.max,
        card.min = card_min(x, weights),
        weights = weights,
        nstart = 10,
        threads = "auto",
        param = NULL
      ),
      error = function(cond) {
        NULL
      }
    )
  } else {
    if (!is.matrix(centers)) {
      centers <- as.matrix(centers)
    }

    cl <- tryCatch(
      CEC::cec(
        x,
        centers,
        iter.max = iter.max,
        card.min = card_min(x, weights),
        weights = weights,
        param = NULL
      ),
      error = function(cond) {
        NULL
      }
    )
  }

  iter_count <- cl$iterations

  if (is.null(cl)) {
    split <- FALSE
  } else {
    sh <- rbind(
      mapply(
        .cov2shape,
        cl$covariances,
        asplit(cl$centers, 1),
        SIMPLIFY = TRUE
      ),
      n = Rfast::Table(cl$cluster)
    )
  }

  while (split) {
    test_width <- sh[3, ] / split.width
    test_height <- sh[4, ] / split.height
    test_density <- split.density /
      (sh[6, ] / ((sh[3, ] / 2) * (sh[4, ] / 2) * pi))
    split_test <- test_width > 1 | test_height > 1 | test_density > 1

    if (any(split_test) & (iter_count < iter.max)) {
      to_split <- which.max(sh[6, ])
      ix <- cl$cluster == to_split

      sub_cl <- tryCatch(
        CEC::cec(
          x[ix, , drop = FALSE],
          1,
          iter.max = max(iter.max - iter_count, 1),
          card.min = card_min(x[ix, , drop = FALSE], weights[ix]),
          split = TRUE,
          split.tries = 1,
          split.limit = 2,
          split.depth = 1,
          split.initial.starts = 1,
          weights = weights[ix]
        ),
        error = function(cond) {
          NULL
        }
      )

      iter_count <- iter_count + sub_cl$iterations

      tmp_cl <- tryCatch(
        CEC::cec(
          x,
          rbind(sub_cl$centers, t(sh)[-to_split, 1:2, drop = FALSE]),
          iter.max = max(iter.max - iter_count, 1),
          card.min = card_min(x, weights),
          weights = weights,
          param = NULL
        ),
        error = function(cond) {
          cl
        }
      )

      iter_count <- iter_count + tmp_cl$iterations

      if (
        1 - tmp_cl$cost.function / cl$cost.function >
          split.sensitivity / sqrt(tmp_cl$nclusters)
      ) {
        cl <- tmp_cl
        sh <- rbind(
          mapply(
            .cov2shape,
            cl$covariances,
            asplit(cl$centers, 1),
            SIMPLIFY = TRUE
          ),
          n = Rfast::Table(cl$cluster)
        )
      } else {
        split <- FALSE
      }
    } else {
      split <- FALSE
    }
  }

  if (is.null(cl)) {
    return(NULL)
  }

  keep <- sh[6, ] >= min.size
  if (!any(keep)) {
    return(NULL)
  }

  t(sh[, keep, drop = FALSE])
}

