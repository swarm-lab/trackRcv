# Flags the blobs to exclude when the identification step estimates object
# size limits. `summ` is a data frame with `width`, `height` and `density`
# columns. Returns one logical per row: `TRUE` means exclude.
#
# A row with a non-finite value, or with a zero `width` or `height`, is
# always excluded. `mvoutlier::pcout()` runs on the other rows only when it
# can give a result: at least 2 rows, and a positive MAD in every column.
# Otherwise none of the other rows is excluded.
.trk_flag_outliers <- function(summ) {
  feats <- cbind(summ[["width"]], summ[["height"]], summ[["density"]])
  usable <- rowSums(is.finite(feats)) == 3L & feats[, 1] > 0 & feats[, 2] > 0
  flagged <- !usable
  x <- feats[usable, , drop = FALSE]

  if (nrow(x) >= 2L && all(apply(x, 2, stats::mad) > 0)) {
    flagged[usable] <- mvoutlier::pcout(scale(x))$wfinal01 == 0
  }

  flagged
}
