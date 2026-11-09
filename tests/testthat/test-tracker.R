get_seed <- function() {
  get0(".Random.seed", envir = globalenv(), inherits = FALSE)
}

restore_seed <- function(seed) {
  if (is.null(seed)) {
    if (!is.null(get_seed())) rm(".Random.seed", envir = globalenv())
  } else {
    assign(".Random.seed", seed, envir = globalenv())
  }
}

# Runs f() with the global random number state set by `seed` (or removed when
# `seed` is NULL). The previous state is restored afterwards.
with_rng <- function(seed, f) {
  old <- get_seed()
  on.exit(restore_seed(old), add = TRUE)

  if (is.null(seed)) {
    restore_seed(NULL)
  } else {
    set.seed(seed)
  }

  f()
}

two_blobs <- function() {
  with_rng(1, function() {
    xy <- round(rbind(
      cbind(rnorm(300, 0, 5), rnorm(300, 0, 5)),
      cbind(rnorm(300, 8, 5), rnorm(300, 0, 5))
    ))
    cbind(xy, w = round(runif(nrow(xy), 50, 255)))
  })
}

kbox_args <- list(
  centers = 3,
  iter.max = 1000,
  split = TRUE,
  split.width = 20,
  split.height = 20,
  split.density = 0.5,
  min.size = 10
)

test_that("kbox() with the same seed gives the same result", {
  pos <- two_blobs()
  res <- replicate(
    8,
    do.call(kbox, c(list(pos), kbox_args, list(seed = 7))),
    simplify = FALSE
  )

  for (r in res[-1]) {
    expect_identical(r, res[[1]])
  }
})

test_that("kbox() without a seed can differ between calls", {
  pos <- two_blobs()
  res <- replicate(
    20,
    do.call(kbox, c(list(pos), kbox_args)),
    simplify = FALSE
  )

  expect_gt(length(unique(lapply(res, as.vector))), 1)
})

test_that("kbox() leaves the global random number state unchanged", {
  pos <- two_blobs()

  with_rng(42, function() {
    before <- get_seed()
    do.call(kbox, c(list(pos), kbox_args, list(seed = 7)))
    expect_identical(get_seed(), before)
  })
})

test_that("kbox() does not create a random number state that was absent", {
  pos <- two_blobs()

  with_rng(NULL, function() {
    do.call(kbox, c(list(pos), kbox_args, list(seed = 7)))
    expect_null(get_seed())
  })
})

test_that("kbox() restores the random number state after an error", {
  pos <- two_blobs()

  with_rng(42, function() {
    before <- get_seed()
    expect_error(
      do.call(
        kbox,
        c(
          list(pos),
          modifyList(kbox_args, list(split.width = "a")),
          list(seed = 7)
        )
      )
    )
    expect_identical(get_seed(), before)
  })
})

test_that("kbox() rejects an invalid seed and names the argument", {
  pos <- two_blobs()

  expect_error(kbox(pos, seed = "a"), "`seed`")
  expect_error(kbox(pos, seed = c(1, 2)), "`seed`")
  expect_error(kbox(pos, seed = NA_real_), "`seed`")
  expect_error(kbox(pos, seed = Inf), "`seed`")
})
