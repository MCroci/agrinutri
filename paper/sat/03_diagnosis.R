# In-season diagnosis: per field, the 2025 peak-canopy Sentinel-2 scene (highest mean NDVI in
# the crop window: wheat March-June, maize June-September), its NDVI and Nitrogen Nutrition
# Index. The diagnosis does not depend on the balance, so it is shared by both scenarios.
# Outputs: paper/sat/out/ndvi_<id>.tif, out/nni_<id>.tif, data/peak_scenes.csv
OUT_DIAG <- "paper/sat/out"
Sys.setenv(SAT_SCENARIO = "reference"); source("paper/sat/00_config.R")
S2B <- c("B02","B03","B04","B05","B06","B07","B08","B8A","B11","B12")
rows <- list()
for (i in seq_len(nrow(FIELDS))) {
  fi <- FIELDS[i, ]; wheat <- fi$field_id == 5
  sc <- list.files(file.path(S2, fi$area_id), pattern = "^S2_2025.*[.]tif$", full.names = TRUE)
  dt <- regmatches(basename(sc), regexpr("[0-9]{8}", basename(sc)))
  keep <- as.integer(substr(dt, 5, 6)) %in% (if (wheat) 3:6 else 6:9)
  sc <- sc[keep]; dt <- dt[keep]
  nd <- vapply(sc, function(f) { r <- rast(f); names(r) <- S2B
    tryCatch(global(compute_vi(r, "NDVI", scale_factor = 10000), "mean", na.rm = TRUE)[1, 1], error = function(e) NA_real_) }, numeric(1))
  j <- which.max(nd); best <- sc[j]
  r <- rast(best); names(r) <- S2B
  ndvi <- compute_vi(r, "NDVI", scale_factor = 10000)
  m <- estimate_biophysical(raster_path = best, output_dir = tempfile("bio"),
         variables = c("LAI", "Cm", "CNC_Cprot", "FVC"), block_rows = 32)
  nni <- compute_NNI_from_S2(lai_rast = m$LAI, cm_rast = m$Cm, cnc_rast = m$CNC_Cprot,
           cnc_layer = "CNC_Cprot", crop = if (wheat) "wheat" else "maize", fvc = m$FVC)$NNI
  writeRaster(ndvi, file.path(OUT_DIAG, sprintf("ndvi_%d.tif", fi$field_id)), overwrite = TRUE)
  writeRaster(nni,  file.path(OUT_DIAG, sprintf("nni_%d.tif",  fi$field_id)), overwrite = TRUE)
  nv <- values(nni, na.rm = TRUE)
  rows[[i]] <- data.frame(field = fi$label, date = dt[j], mean_ndvi = nd[j], n_nni = length(nv),
    nni_median = median(nv), pct_deficient = 100 * mean(nv < 0.9),
    pct_optimal = 100 * mean(nv >= 0.9 & nv <= 1.1), pct_excess = 100 * mean(nv > 1.1))
  cat(fi$label, dt[j], "\n")
}
write.csv(do.call(rbind, rows), "paper/sat/data/peak_scenes.csv", row.names = FALSE)
