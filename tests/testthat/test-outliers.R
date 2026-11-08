# The helper under test is an app script (`inst/apps/share/r/outliers.R`).
# The track app loads it with `source()`, so the tests do the same.
source(
  system.file("apps", "share", "r", "outliers.R", package = "trackRcv"),
  local = TRUE
)

# Deterministic blob summaries (no random numbers): normal quantiles in a
# fixed shuffled order, so that the columns are not collinear.
blob_summary <- function(n = 200) {
  q <- stats::qnorm(stats::ppoints(n))
  data.frame(
    width = 20 + 3 * q,
    height = 15 + 2 * q[(seq_len(n) * 37) %% n + 1],
    density = 0.5 + 0.1 * q[(seq_len(n) * 91) %% n + 1]
  )
}

test_that("a usable summary gives the same flags as pcout on the scaled data", {
  summ <- blob_summary()
  direct <- mvoutlier::pcout(
    cbind(scale(summ$width), scale(summ$height), scale(summ$density))
  )$wfinal01 ==
    0

  expect_identical(.trk_flag_outliers(summ), direct)
})

test_that("an extreme blob is flagged", {
  summ <- rbind(
    blob_summary(),
    data.frame(width = 90, height = 70, density = 3)
  )

  expect_identical(.trk_flag_outliers(summ)[nrow(summ)], TRUE)
})

test_that("a data.table is accepted", {
  summ <- blob_summary()

  expect_identical(
    .trk_flag_outliers(data.table::as.data.table(summ)),
    .trk_flag_outliers(summ)
  )
})

test_that("a row with a non-finite value is flagged and does not change the rest", {
  summ <- blob_summary()

  for (bad in list(Inf, NaN, NA_real_)) {
    with_bad <- rbind(data.frame(width = 20, height = 15, density = bad), summ)
    flags <- .trk_flag_outliers(with_bad)

    expect_identical(flags[1], TRUE)
    expect_identical(flags[-1], .trk_flag_outliers(summ))
  }
})

test_that("a row with zero width or zero height is flagged", {
  summ <- blob_summary()
  zero_w <- rbind(data.frame(width = 0, height = 15, density = Inf), summ)
  zero_h <- rbind(data.frame(width = 20, height = 0, density = Inf), summ)

  expect_identical(.trk_flag_outliers(zero_w)[1], TRUE)
  expect_identical(.trk_flag_outliers(zero_h)[1], TRUE)
})

test_that("a single usable row is kept", {
  expect_identical(
    .trk_flag_outliers(data.frame(width = 20, height = 15, density = 0.5)),
    FALSE
  )
})

test_that("no rows give no flags", {
  expect_identical(
    .trk_flag_outliers(data.frame(
      width = numeric(0),
      height = numeric(0),
      density = numeric(0)
    )),
    logical(0)
  )
})

test_that("rows that are all identical are kept without an error", {
  summ <- data.frame(
    width = rep(20, 50),
    height = rep(15, 50),
    density = rep(0.5, 50)
  )

  expect_identical(.trk_flag_outliers(summ), rep(FALSE, 50))
})

test_that("a constant column is kept without an error", {
  summ <- blob_summary()
  summ$width <- 20

  expect_identical(.trk_flag_outliers(summ), rep(FALSE, nrow(summ)))
})

test_that("a column with more than half equal values is kept without an error", {
  summ <- blob_summary()
  summ$width[1:120] <- 20

  expect_identical(.trk_flag_outliers(summ), rep(FALSE, nrow(summ)))
})

test_that("a summary with only unusable rows is all flagged", {
  summ <- data.frame(
    width = c(0, 10, NA),
    height = c(5, 0, 5),
    density = c(Inf, Inf, 1)
  )

  expect_identical(.trk_flag_outliers(summ), rep(TRUE, 3))
})
