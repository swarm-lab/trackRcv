.pdiff <- function(a, b) {
  a - matrix(b, nrow = length(a), ncol = length(b), byrow = TRUE)
}

.cov2shape <- function(sigma, mu) {
  eig <- eigen(sigma, symmetric = TRUE)
  eigval <- eig$values
  eigvec <- eig$vectors
  eigidx <- order(eigval)

  if (eigidx[1] == 1) {
    a <- 2 * sqrt(eigval[2])
    b <- 2 * sqrt(eigval[1])
  } else {
    a <- 2 * sqrt(eigval[1])
    b <- 2 * sqrt(eigval[2])
  }

  alpha <- atan(eigvec[2, 1] / eigvec[2, 2])

  c(
    x = mu[1],
    y = mu[2],
    width = b * 2,
    height = a * 2,
    angle = (180 * alpha / pi) + 90
  )
}

.dist2ellipse <- function(x, y, cx, cy, width, height, angle) {
  relx <- -.pdiff(cx, x)
  rely <- -.pdiff(cy, y)
  cosa <- cos(-angle)
  sina <- sin(-angle)
  sqrt(
    ((relx * cosa - rely * sina) / (width / 2))^2 +
      ((relx * sina + rely * cosa) / (height / 2))^2
  )
}

.xyangle <- function(x, y, directed = FALSE) {
  if (missing(y)) {
    y <- x[, 2]
    x <- x[, 1]
  }
  out <- atan2(y, x)
  if (!directed) out <- out %% pi
  out
}