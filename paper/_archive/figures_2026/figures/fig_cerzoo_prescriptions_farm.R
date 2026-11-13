# Farm-scale prescription strategies: the 5 methods applied to ALL 8 CERZOO fields.
# Per field: NDVI + NNI (peak canopy) and the balance N target; each strategy built
# with build_strip_prescription (2-D cells), then combined per strategy.
suppressMessages({
  pkgload::load_all("C:/Users/michele.croci/Documents/GitHub/NFert", quiet = TRUE)
  library(terra); library(sf); library(ggplot2)
})
SP  <- "C:/Users/MICHEL~1.CRO/AppData/Local/Temp/claude/C--Users-michele-croci-Documents-GitHub-NFert/b5b9999e-d385-4c3e-84cf-b776ad94bd7c/scratchpad"
BASE<- "C:/Users/michele.croci/Desktop/presto-deploy/data/rasters/downloads_cerzoo_multiband"
RAW <- "C:/Users/michele.croci/Desktop/presto-deploy/data/raw/cerzoo"
aoi <- st_transform(st_read(file.path(RAW, "aoi_multi_cerzoo_fields.geojson"), quiet = TRUE), 32632)
Nrast <- rast(file.path(SP, "mc_farm_out/N_mean_10m.tif"))
S2B <- c("B02","B03","B04","B05","B06","B07","B08","B8A","B11","B12")
strat <- list(list(n="Uniform",              v="uniform"),
              list(n="Calibration (inverse)", v="calibration", inv=TRUE),
              list(n="Calibration (direct)",  v="calibration", inv=FALSE),
              list(n="Quantile classes",      v="classes", inv=TRUE),
              list(n="NNI zones",             v="nni"))

out <- list()
for (i in seq_len(nrow(aoi))) {
  fld <- aoi[i, ]; sc <- list.files(file.path(BASE, fld$area_id), pattern = "^S2_.*[.]tif$", full.names = TRUE)
  if (!length(sc)) next
  dt <- regmatches(basename(sc), regexpr("[0-9]{8}", basename(sc)))
  is_wheat <- grepl("wheat", fld$X2025_crops, ignore.case = TRUE)
  sel <- which(as.integer(substr(dt, 5, 6)) %in% (if (is_wheat) 3:6 else 6:9)); if (!length(sel)) next
  best <- NA; bv <- -Inf
  for (j in sel) { rj <- rast(sc[j]); if (nlyr(rj) == 10) names(rj) <- S2B
    nd <- tryCatch(global(compute_vi(rj, "NDVI", scale_factor = 10000), "mean", na.rm = TRUE)[1,1], error = function(e) NA)
    if (is.finite(nd) && nd > bv) { bv <- nd; best <- sc[j] } }
  if (is.na(best)) next
  rj <- rast(best); names(rj) <- S2B
  ndvi <- compute_vi(rj, "NDVI", scale_factor = 10000)
  nni <- tryCatch({
    m <- estimate_biophysical(raster_path = best, output_dir = tempfile("b", SP),
                              variables = c("LAI","Cm","CNC_Cprot","FVC"), block_rows = 32)
    compute_NNI_from_S2(lai_rast = m$LAI, cm_rast = m$Cm, cnc_rast = m$CNC_Cprot,
                        cnc_layer = "CNC_Cprot", crop = if (is_wheat) "wheat" else "maize", fvc = m$FVC)$NNI
  }, error = function(e) NULL)
  Nt <- terra::extract(Nrast, vect(fld), fun = mean, na.rm = TRUE)[, 2]
  if (!is.finite(Nt)) next
  for (s in strat) {
    rx <- tryCatch(build_strip_prescription(fld, machine_width = 24, cell_length = 30,
             variability = s$v, vi_raster = ndvi, nni_raster = nni, n_target = Nt,
             min_dose = Nt * 0.6, max_dose = Nt * 1.35,
             calibration_inverse = if (!is.null(s$inv)) s$inv else TRUE,
             preserve_mean = TRUE, crs_metric = 32632), error = function(e) NULL)
    if (is.null(rx) || nrow(rx) == 0) next
    rx <- rx[, "dose"]; rx$strategy <- s$n
    out[[length(out) + 1L]] <- rx
  }
}
all <- do.call(rbind, out)
all$strategy <- factor(all$strategy, levels = sapply(strat, `[[`, "n"))
cat(sprintf("strategies: %d features | dose range %.0f..%.0f\n", nrow(all), min(all$dose), max(all$dose)))

p <- ggplot(all) +
  geom_sf(aes(fill = dose), color = NA) +
  geom_sf(data = aoi, fill = NA, color = "grey20", linewidth = 0.2) +
  facet_wrap(~strategy, ncol = 3) +
  scale_fill_viridis_c(option = "viridis", name = expression("N dose (kg N ha"^-1*")")) +
  theme_void(base_size = 11) +
  theme(legend.position = "bottom", legend.key.width = unit(2.2, "cm"), legend.key.height = unit(0.35, "cm"),
        strip.text = element_text(face = "bold", size = 11), plot.margin = margin(2,2,2,2)) +
  labs(title = "Variable-rate prescription strategies across the CERZOO farm") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))
ggsave(file.path(SP, "fig_presc_farm.png"), p, width = 12, height = 8.2, dpi = 200, bg = "white")
cat("saved fig_presc_farm.png\n")
