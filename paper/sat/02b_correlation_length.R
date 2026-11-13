# Farm-total uncertainty versus the soil-error correlation length (Section 2.6).
#
# Block model: the mapped area A is a mosaic of independent correlation blocks of side L, so
# n_eff = min(max(A / L^2, 1), N) and, for a response that is linear in the soil error,
#   SD(farm total; L) = SD_sys / sqrt(n_eff),
# where SD_sys is the SD of the farm total when ONE correlated error realisation per property is
# applied to every pixel (fully systematic error, n_eff = 1). SD_sys is obtained by Monte Carlo
# at pixel level: evaluating the balance on the field-mean soil instead turns the class
# thresholds of the balance (C/N class, texture group) into steps and breaks the scaling.
# The block formula is checked by re-evaluating the pixel-level balance at two lengths L.
# The short-range limit is also computed from the independent per-pixel Monte Carlo of script 02.
# Outputs: data/corr_length_curve.csv, data/corr_length_checks.csv
source("paper/sat/00_config.R")
library(parallel)
K_SYS <- 400L; K_CHECK <- 150L; CHECK_L <- c(100, 340)

soil10 <- read_soil()
soil20 <- aggregate(soil10[[c("clay", "sand", "toc", "tn")]], 2, mean, na.rm = TRUE)
fid20  <- aggregate(soil10$field, 2, "modal", na.rm = TRUE)
pv <- data.frame(values(c(soil20, fid20))); pv <- pv[complete.cases(pv), ]
a_px <- prod(res(soil20)) / 1e4                              # ha per pixel
A_m2 <- nrow(pv) * prod(res(soil20)); N_px <- nrow(pv)

cl <- makeCluster(max(1L, min(8L, detectCores() - 2L)))
on.exit(stopCluster(cl), add = TRUE)
clusterEvalQ(cl, { pkgload::load_all(".", quiet = TRUE); NULL })
clusterExport(cl, c("dose_fn", "FIELDS", "RMSE", "RHO", "pv", "a_px"))

# one correlated realisation per property applied to all pixels; sigma scaled by `s`
total_t <- function(z, s) {
  clay <- pmin(pmax(pv$clay + RMSE[["clay"]] * s * z[1], 1), 90)
  sand <- pmin(pmax(pv$sand + RMSE[["sand"]] * s * z[2], 1), 98 - clay)
  toc  <- pmax(pv$toc + RMSE[["toc"]] * s * z[3], 0.05)
  tn   <- pmax(pv$tn  + RMSE[["tn"]]  * s * z[4], 0.005)
  d <- numeric(nrow(pv))
  for (id in unique(pv$field)) {
    j <- which(pv$field == id)
    d[j] <- dose_fn(FIELDS[FIELDS$field_id == id, ], clay[j], sand[j], toc[j], tn[j])
  }
  sum(d) * a_px / 1000                                        # t N
}
clusterExport(cl, "total_t")
draw_z <- function(n) { set.seed(20260300L)
  a <- function(r) { x <- rnorm(n); cbind(x, r * x + sqrt(1 - r^2) * rnorm(n)) }
  cbind(a(RHO[["clay_sand"]]), a(RHO[["toc_tn"]])) }
run <- function(Z, s) unlist(parLapply(cl, seq_len(nrow(Z)), function(i) total_t(Z[i, ], s)))

Z <- draw_z(K_SYS)
T0 <- total_t(c(0, 0, 0, 0), 0)
T_sys <- run(Z, 1)
cat(sprintf("deterministic total %.3f t | systematic: mean %.3f, SD %.4f t (%.2f %%)\n",
            T0, mean(T_sys), sd(T_sys), 100 * sd(T_sys) / mean(T_sys)))

L_grid <- c(20, 30, 45, 70, 100, 150, 225, 340, 500, 750, 1100)
curve <- data.frame(L_m = L_grid, n_eff = pmin(pmax(A_m2 / L_grid^2, 1), N_px))
curve$sd_total_t <- sd(T_sys) / sqrt(curve$n_eff)
curve$sd_pct <- 100 * curve$sd_total_t / mean(T_sys)
write.csv(curve, file.path(DAT, "corr_length_curve.csv"), row.names = FALSE)

# direct checks of the block formula at two lengths
Zc <- Z[seq_len(K_CHECK), ]
chk <- do.call(rbind, lapply(CHECK_L, function(L) {
  ne <- min(max(A_m2 / L^2, 1), N_px); Tc <- run(Zc, 1 / sqrt(ne))
  data.frame(L_m = L, n_eff = ne, sd_direct_pct = 100 * sd(Tc) / mean(T_sys),
             sd_block_pct = 100 * sd(T_sys) / sqrt(ne) / mean(T_sys))
}))
# short-range limit from the independent per-pixel Monte Carlo (script 02)
sdp <- rast(file.path(OUT, "N_sd.tif")); sv <- values(sdp)[, 1]; sv <- sv[is.finite(sv)]
indep_pct <- 100 * (sqrt(sum((sv * a_px)^2)) / 1000) / mean(T_sys)
chk <- rbind(chk, data.frame(L_m = NA, n_eff = N_px, sd_direct_pct = indep_pct,
                             sd_block_pct = 100 * sd(T_sys) / sqrt(N_px) / mean(T_sys)))
write.csv(chk, file.path(DAT, "corr_length_checks.csv"), row.names = FALSE)
print(round(curve, 3)); print(round(chk, 3))
