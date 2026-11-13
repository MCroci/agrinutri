# Propagation of the soil-input uncertainty through the balance (Section 2.6):
#  (a) per-pixel Monte Carlo on a 20 m grid (K draws, correlated Gaussian soil errors)
#  (b) first-order variance decomposition per field (texture vs carbon-nitrogen)
# Outputs: out/N_sd.tif, out/N_mc_mean.tif, data/uncert_pixel_summary.csv,
#          data/variance_decomposition.csv   (the correlation-length curve is in 02b)
source("paper/sat/00_config.R")
library(parallel)
K_PIXEL <- 100L; N_VARDEC <- 3000L
acc <- read.csv(file.path(DAT, "farm_accounting.csv")); acc <- acc[acc$field != "Farm", ]
fsm <- read.csv(file.path(DAT, "field_soil_means.csv"))  # field-mean soil of the soil run
area_ha <- setNames(acc$area_ha, sub("^F", "", acc$field))

cl <- makeCluster(max(1L, min(8L, detectCores() - 2L)))
on.exit(stopCluster(cl), add = TRUE)
clusterEvalQ(cl, { pkgload::load_all(".", quiet = TRUE); NULL })
clusterExport(cl, c("dose_fn", "perturb_soil", "FIELDS", "RMSE", "RHO", "area_ha", "fsm"))
fld_of <- function(id) FIELDS[FIELDS$field_id == id, ]

# ---- (a) per-pixel Monte Carlo on the 20 m grid --------------------------------
soil10 <- read_soil()
soil20 <- aggregate(soil10[[c("clay", "sand", "toc", "tn")]], 2, mean, na.rm = TRUE)
fid20  <- aggregate(soil10$field, 2, "modal", na.rm = TRUE)
pv <- data.frame(values(c(soil20, fid20))); pv$cell <- seq_len(nrow(pv))
pv <- pv[complete.cases(pv), ]
cat("pixels on the 20 m grid:", nrow(pv), "\n")
clusterExport(cl, c("pv", "K_PIXEL"))
draws <- parLapply(cl, seq_len(K_PIXEL), function(k) {
  set.seed(20260100L + k)
  out <- numeric(nrow(pv))
  for (id in unique(pv$field)) {
    j <- which(pv$field == id)
    s <- perturb_soil(pv$clay[j], pv$sand[j], pv$toc[j], pv$tn[j])
    out[j] <- dose_fn(FIELDS[FIELDS$field_id == id, ], s$clay, s$sand, s$toc, s$tn)
  }
  out
})
D <- do.call(cbind, draws)
pv$N_mc_mean <- rowMeans(D); pv$N_sd <- apply(D, 1, sd)
for (nm in c("N_mc_mean", "N_sd")) {
  r <- rast(soil20[[1]]); values(r) <- NA; r[pv$cell] <- pv[[nm]]; names(r) <- nm
  writeRaster(r, file.path(OUT, paste0(nm, ".tif")), overwrite = TRUE)
}
pixel <- data.frame(K = K_PIXEL, n_pixels = nrow(pv), mean_dose = mean(pv$N_mc_mean),
                    mean_sd = mean(pv$N_sd), sd_pct = 100 * mean(pv$N_sd) / mean(pv$N_mc_mean))
write.csv(pixel, file.path(DAT, "uncert_pixel_summary.csv"), row.names = FALSE)
print(pixel)

# ---- (b) variance decomposition at the field-mean soil ---------------------------
tasks <- expand.grid(field = FIELDS$field_id, group = c("texture", "cn"), stringsAsFactors = FALSE)
clusterExport(cl, c("tasks", "N_VARDEC"))
vv <- parLapply(cl, seq_len(nrow(tasks)), function(i) {
  set.seed(20260200L + i)
  m <- fsm[fsm$field_id == tasks$field[i], ]
  s <- perturb_soil(rep(m$clay, N_VARDEC), rep(m$sand, N_VARDEC), rep(m$toc, N_VARDEC),
                    rep(m$tn, N_VARDEC), groups = tasks$group[i])
  var(dose_fn(FIELDS[FIELDS$field_id == tasks$field[i], ], s$clay, s$sand, s$toc, s$tn))
})
tasks$var <- unlist(vv)
vd <- reshape(tasks, idvar = "field", timevar = "group", direction = "wide")
names(vd) <- c("field_id", "var_texture", "var_cn")
vd$share_texture <- 100 * vd$var_texture / (vd$var_texture + vd$var_cn)
vd$crop_group <- ifelse(vd$field_id == 5, "wheat", "maize")
vd$area_ha <- area_ha[as.character(vd$field_id)]
write.csv(vd, file.path(DAT, "variance_decomposition.csv"), row.names = FALSE)
print(aggregate(share_texture ~ crop_group, vd, function(x) mean(x)))
