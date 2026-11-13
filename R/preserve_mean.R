# Mass-balance constraint shared by the variable-rate functions.
#
# Rescale `dose` so that its `w`-weighted mean equals `target` while every
# value stays in [lo, hi] (water filling: values that hit a bound are frozen
# and the remaining ones are rescaled again). If the target cannot be reached
# within the bounds the closest feasible map is returned with a warning.
.preserve_mean <- function(dose, w, target, lo = 0, hi = Inf, tol = 1e-9,
                           max_iter = 100L) {
  ok <- is.finite(dose) & is.finite(w) & w > 0
  if (!any(ok) || !is.finite(target)) return(dose)
  d <- pmin(pmax(dose[ok], lo), hi)
  ww <- w[ok]
  W <- sum(ww)
  if (target <= lo) {
    d[] <- lo
  } else if (target >= hi) {
    d[] <- hi
  } else {
    for (i in seq_len(max_iter)) {
      gap <- target * W - sum(d * ww)
      if (abs(gap) <= tol * target * W) break
      free <- if (gap > 0) d < hi else d > lo
      s_free <- sum(d[free] * ww[free])
      if (!any(free)) break
      if (s_free > 0) {
        d[free] <- d[free] * (1 + gap / s_free)
      } else {
        d[free] <- d[free] + gap / sum(ww[free])
      }
      d <- pmin(pmax(d, lo), hi)
    }
  }
  achieved <- sum(d * ww) / W
  if (abs(achieved - target) > 1e-6 * max(1, abs(target)))
    warning(sprintf(paste0("The field mean (%.1f kg/ha) cannot reach the target ",
                           "(%.1f kg/ha) within the dose bounds [%s, %s]."),
                    achieved, target, format(lo), format(hi)), call. = FALSE)
  dose[ok] <- d
  dose
}
