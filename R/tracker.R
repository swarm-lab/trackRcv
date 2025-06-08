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
#' @param x A numeric matrix with two columns.
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
#' @param min.size The minimum authorized size (in number of items) of a cluster.
#'  If a cluster is smaller than \code{min.size}, the function will attempt to
#'  split it in two.
#'
#' @param split.sensitivity The minimum amount of improvement in the cost
#'  function of the cross-entropy clustering for a splitting event to be
#'  considered valid.
#'
#' @return A matrix with 6 columns: x and y coordinates of the centers of the
#'  clusters, width, height, and angle of the covariance ellipse best describing
#'  each cluster, and the number of element in each cluster.
#'
#' @author Simon Garnier, \email{garnier@@njit.edu}
#'
#' @examples
#' x <- c(rnorm(25, 4), rnorm(25, -2))
#' y <- c(rnorm(25, 2), rnorm(25, -3))
#' k <- kbox(cbind(x, y), 2)
#' plot(x, y, asp = 1)
#' apply(k, 1, function(k) {
#'   lines(ellipse(k[1], k[2], k[3], k[4], k[5]))
#' })
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
  split.sensitivity = 0
) {
  if (!is.matrix(x)) {
    x <- as.matrix(x)
  }

  if (is.null(dim(centers))) {
    cl <- tryCatch(
      CEC::cec(
        x,
        centers,
        iter.max = iter.max,
        card.min = min.size,
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
        card.min = min.size,
        param = NULL
      ),
      error = function(cond) {
        NULL
      }
    )
  }

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
      (sh[6, ] /
        ((sh[3, ] / 2) *
          (sh[4, ] / 2) *
          pi))
    to_split <- test_width > 1 | test_height > 1 | test_density > 1

    if (any(to_split)) {
      tmp_cl <- tryCatch(
        CEC::cec(
          x,
          cl$nclusters,
          iter.max = iter.max,
          card.min = min.size,
          param = NULL,
          nstart = 10,
          threads = "auto"
        ),
        error = function(cond) {
          NULL
        }
      )

      if (is.null(tmp_cl)) {
        tmp_test_width <- 2
      } else {
        tmp_sh <- rbind(
          mapply(
            .cov2shape,
            tmp_cl$covariances,
            asplit(tmp_cl$centers, 1),
            SIMPLIFY = TRUE
          ),
          n = Rfast::Table(tmp_cl$cluster)
        )

        tmp_test_width <- tmp_sh[3, ] / split.width
        tmp_test_height <- tmp_sh[4, ] / split.height
        tmp_test_density <- split.density /
          (tmp_sh[6, ] /
            ((tmp_sh[3, ] / 2) *
              (tmp_sh[4, ] / 2) *
              pi))
      }

      if (
        any(tmp_test_width > 1 | tmp_test_height > 1 | tmp_test_density > 1)
      ) {
        tmp_tmp_centers <- rbind(
          cl$centers[!to_split, ],
          do.call(
            rbind,
            lapply(which(to_split), function(i) {
              cluster::clara(x[cl$cluster == i, ], 2, samples = 50)$medoids
            })
          )
        )

        tmp_tmp_cl <- tryCatch(
          CEC::cec(
            x,
            tmp_tmp_centers,
            iter.max = iter.max,
            card.min = min.size,
            param = NULL
          ),
          error = function(cond) {
            cl
          }
        )

        if (
          1 - tmp_tmp_cl$cost.function / cl$cost.function >
            split.sensitivity / sqrt(tmp_tmp_cl$nclusters)
        ) {
          cl <- tmp_tmp_cl
          sh <- rbind(
            mapply(
              .cov2shape,
              tmp_tmp_cl$covariances,
              asplit(tmp_tmp_cl$centers, 1),
              SIMPLIFY = TRUE
            ),
            n = Rfast::Table(tmp_tmp_cl$cluster)
          )
        } else {
          split <- FALSE
        }
      } else {
        cl <- tmp_cl
        sh <- tmp_sh
        split <- FALSE
      }
    } else {
      split <- FALSE
    }
  }

  if (is.null(cl)) {
    NULL
  } else {
    t(sh)
  }
}
