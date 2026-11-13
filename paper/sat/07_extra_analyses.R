# Zero-cost analyses added after the structure review (Sections 2.2, 2.6, 3.2, 3.4):
#  (1) spatial structure of the soil-map error: leave-one-point-out residuals of a random-forest
#      re-fit on the same Sentinel-2 bare-soil (SBSI) predictors, standardised, pooled over the
#      four properties, binned semivariogram against a permutation envelope -> bound on L
#  (2) mean shift: Monte Carlo mean dose vs deterministic dose on the same 20 m support
#  (3) input-error sensitivity: chi-square interval of a 20-point RMSE and Monte Carlo at the
#      interval ends (the response is not linear because of the class thresholds)
#  (4) area of applicability (AOA, preceding soil run): dose inside vs outside
#  (5) prescription metrics per strategy: N redistributed, CV, share of area at the dose bounds
# Outputs: data/residual_variogram.csv, data/residual_loo.csv, data/mean_shift.csv,
#          data/rmse_sensitivity.csv, data/aoa_dose.csv, data/strategy_metrics.csv
source("paper/sat/00_config.R")
suppressMessages({ library(parallel); library(ranger) })
PTS <- file.path(ROOT, "data/processed/cerzoo_soil_points.gpkg")
SBSI <- file.path(RAW, "sbsi_cerzoo_id_1.tif")
AOA_DIR <- file.path(SOIL_DIR, "3_area_of_applicability")

# ---- (1) residual spatial structure ------------------------------------------------
pts <- st_read(PTS, quiet = TRUE)
X <- terra::extract(rast(SBSI), vect(pts), ID = FALSE); names(X) <- paste0("b", seq_len(ncol(X)))
tg <- c(clay = "argilla_pct", sand = "sabbia_pct", toc = "toc_pct", tn = "tn_pct")
loo <- sapply(names(tg), function(p) {
  y <- pts[[tg[[p]]]]
  vapply(seq_along(y), function(i) {
    m <- ranger(x = X[-i, , drop = FALSE], y = y[-i], num.trees = 500, seed = 20260700L)
    predict(m, X[i, , drop = FALSE])$predictions
  }, numeric(1))
})
obs <- sapply(tg, function(t) pts[[t]])
res <- obs - loo
rmse_refit <- sqrt(colMeans(res^2))
z <- sweep(res, 2, rmse_refit, "/")                     # standardised residuals
xy <- st_coordinates(pts)
write.csv(data.frame(sample = pts$sample_id, x = xy[, 1], y = xy[, 2], res),
          file.path(DAT, "residual_loo.csv"), row.names = FALSE)
D <- as.matrix(dist(xy)); up <- upper.tri(D)
brk <- c(0, 150, 300, 450, 600, 1000)
semiv <- function(zz) {                                  # pooled over properties
  g <- sapply(seq_len(ncol(zz)), function(k) { d2 <- outer(zz[, k], zz[, k], "-")^2 / 2; d2[up] })
  as.vector(tapply(rowMeans(g), cut(D[up], brk), mean))
}
g_obs <- semiv(z)
set.seed(20260701L)
g_perm <- replicate(999, semiv(z[sample(nrow(z)), , drop = FALSE]))
vg <- data.frame(bin = levels(cut(D[up], brk)), n_pairs = as.vector(table(cut(D[up], brk))),
                 gamma = as.vector(g_obs), env_lo = apply(g_perm, 1, quantile, 0.025),
                 env_hi = apply(g_perm, 1, quantile, 0.975),
                 p_low = rowMeans(g_perm <= g_obs))     # one-sided: structure lowers short-lag gamma
write.csv(vg, file.path(DAT, "residual_variogram.csv"), row.names = FALSE)
cat("re-fit LOO RMSE:", round(rmse_refit, 4), "\n"); print(vg)

# ---- (2) mean shift ---------------------------------------------------------------------
soil10 <- read_soil()
soil20 <- aggregate(soil10[[c("clay", "sand", "toc", "tn")]], 2, mean, na.rm = TRUE)
fid20  <- aggregate(soil10$field, 2, "modal", na.rm = TRUE)
pv <- data.frame(values(c(soil20, fid20))); pv$cell <- seq_len(nrow(pv)); pv <- pv[complete.cases(pv), ]
pv$det <- NA_real_
for (id in unique(pv$field)) { j <- which(pv$field == id)
  pv$det[j] <- dose_fn(FIELDS[FIELDS$field_id == id, ], pv$clay[j], pv$sand[j], pv$toc[j], pv$tn[j]) }
pv$mc <- values(rast(file.path(OUT, "N_mc_mean.tif")))[pv$cell, 1]
ms <- aggregate(cbind(det, mc) ~ field, pv, mean)
ms <- rbind(ms, data.frame(field = 0, det = mean(pv$det), mc = mean(pv$mc)))
ms$shift <- ms$mc - ms$det; ms$shift_pct <- 100 * ms$shift / ms$det
ms$field <- ifelse(ms$field == 0, "Farm", paste0("F", ms$field))
write.csv(ms, file.path(DAT, "mean_shift.csv"), row.names = FALSE); print(ms)

# ---- (3) RMSE interval and sensitivity -------------------------------------------------
n <- 20
ci <- sqrt(n / qchisq(c(0.975, 0.025), n))              # approx., normal errors
cl <- makeCluster(max(1L, min(8L, detectCores() - 2L))); on.exit(stopCluster(cl), add = TRUE)
clusterEvalQ(cl, { pkgload::load_all(".", quiet = TRUE); NULL })
clusterExport(cl, c("dose_fn", "perturb_soil", "FIELDS", "RMSE", "RHO", "pv"))
mc_sd <- function(scale, K = 50L) {
  clusterExport(cl, "scale", envir = environment())
  Dm <- do.call(cbind, parLapply(cl, seq_len(K), function(k) {
    set.seed(20260100L + k); out <- numeric(nrow(pv))
    for (id in unique(pv$field)) { j <- which(pv$field == id)
      s <- perturb_soil(pv$clay[j], pv$sand[j], pv$toc[j], pv$tn[j], scale = scale)
      out[j] <- dose_fn(FIELDS[FIELDS$field_id == id, ], s$clay, s$sand, s$toc, s$tn) }
    out }))
  c(scale = scale, mean_sd = mean(apply(Dm, 1, sd)), sd_pct = 100 * mean(apply(Dm, 1, sd)) / mean(Dm))
}
sens <- as.data.frame(do.call(rbind, lapply(c(ci[1], 1, ci[2]), mc_sd)))
sens$label <- c("RMSE lower 95% bound", "RMSE as estimated", "RMSE upper 95% bound")
write.csv(sens, file.path(DAT, "rmse_sensitivity.csv"), row.names = FALSE); print(sens)

# ---- (4) area of applicability (preceding run) --------------------------------------------
N10 <- rast(file.path(OUT, "N_mean_10m.tif"))
aoa <- lapply(c("argilla", "sabbia", "toc", "tn"), function(p)
  resample(rast(file.path(AOA_DIR, sprintf("aoa_%s_pct_mask.tif", p))), N10, method = "near"))
inside <- Reduce(`&`, lapply(aoa, function(a) a == 1))
v <- data.frame(N = values(N10)[, 1], ins = values(inside)[, 1]); v <- v[is.finite(v$N) & !is.na(v$ins), ]
a_px <- prod(res(N10)) / 1e4
aoa_t <- aggregate(N ~ ins, v, function(x) c(n = length(x), mean = mean(x), total_t = sum(x) * a_px / 1000))
aoa_t <- data.frame(inside_aoa = aoa_t$ins, aoa_t$N); aoa_t$share_pct <- 100 * aoa_t$n / sum(aoa_t$n)
write.csv(aoa_t, file.path(DAT, "aoa_dose.csv"), row.names = FALSE); print(aoa_t)

# ---- (5) prescription metrics ---------------------------------------------------------------
S <- st_read(file.path(OUT, "strategies.geojson"), quiet = TRUE)
S$area <- as.numeric(st_area(S)) / 1e4
fid <- if ("field" %in% names(S)) S$field else S$field_id
met <- do.call(rbind, lapply(split(cbind(st_drop_geometry(S), fid = fid), S$strategy), function(d) {
  moved <- sum(tapply(seq_len(nrow(d)), d$fid, function(j) sum(abs(d$dose[j] - d$target[j]) * d$area[j]) / 2))
  rel <- d$dose / d$target
  data.frame(strategy = d$strategy[1], N_moved_t = moved / 1000,
             N_moved_pct = 100 * moved / sum(d$target * d$area),
             cv_pct = 100 * sqrt(sum(d$area * (d$dose - weighted.mean(d$dose, d$area))^2) / sum(d$area)) /
               weighted.mean(d$dose, d$area),
             area_at_bounds_pct = 100 * sum(d$area[rel <= 0.601 | rel >= 1.349]) / sum(d$area))
}))
write.csv(met, file.path(DAT, "strategy_metrics.csv"), row.names = FALSE); print(met)
