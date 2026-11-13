# Farm-scale in-season Nitrogen Nutrition Index (NNI) for ALL 8 CERZOO fields.
# Uses the fixed estimate_biophysical (v0.14.2, apply_offset=FALSE). Each field is
# taken at its seasonal peak canopy (max mean NDVI over May-Sep).
suppressMessages({
  pkgload::load_all("C:/Users/michele.croci/Documents/GitHub/NFert", quiet = TRUE)
  library(terra); library(sf); library(ggplot2); library(tidyterra)
})
SP  <- "C:/Users/MICHEL~1.CRO/AppData/Local/Temp/claude/C--Users-michele-croci-Documents-GitHub-NFert/b5b9999e-d385-4c3e-84cf-b776ad94bd7c/scratchpad"
BASE<- "C:/Users/michele.croci/Desktop/presto-deploy/data/rasters/downloads_cerzoo_multiband"
RAW <- "C:/Users/michele.croci/Desktop/presto-deploy/data/raw/cerzoo"
aoi <- st_transform(st_read(file.path(RAW, "aoi_multi_cerzoo_fields.geojson"), quiet = TRUE), 32632)
tmp <- file.path(SP, "nni_farm_tmp"); dir.create(tmp, showWarnings = FALSE, recursive = TRUE)

peak_date <- character(nrow(aoi)); nni_list <- vector("list", nrow(aoi))
for (i in seq_len(nrow(aoi))) {
  fld <- aoi[i, ]; folder <- file.path(BASE, fld$area_id)
  sc <- list.files(folder, pattern = "^S2_.*\\.tif$", full.names = TRUE)
  if (!length(sc)) next
  dt <- regmatches(basename(sc), regexpr("[0-9]{8}", basename(sc)))
  win <- if (grepl("wheat", fld$X2025_crops, ignore.case = TRUE)) 3:6 else 6:9  # crop-specific peak window
  sel <- which(as.integer(substr(dt, 5, 6)) %in% win)
  if (!length(sel)) next
  best <- NA; bestv <- -Inf
  S2B <- c("B02","B03","B04","B05","B06","B07","B08","B8A","B11","B12")
  for (j in sel) {
    rj <- rast(sc[j]); if (nlyr(rj) == 10) names(rj) <- S2B
    nd <- tryCatch(global(compute_vi(rj, "NDVI", scale_factor = 10000), "mean", na.rm = TRUE)[1,1],
                   error = function(e) NA)
    if (is.finite(nd) && nd > bestv) { bestv <- nd; best <- sc[j] }
  }
  if (is.na(best)) next
  peak_date[i] <- regmatches(basename(best), regexpr("[0-9]{8}", basename(best)))
  crop_i <- if (grepl("wheat", fld$X2025_crops, ignore.case = TRUE)) "wheat" else "maize"
  nni <- tryCatch({
    m <- estimate_biophysical(raster_path = best, output_dir = tempfile("bio", tmp),
                              variables = c("LAI","Cm","CNC_Cprot","FVC"), block_rows = 32)
    x <- compute_NNI_from_S2(lai_rast = m$LAI, cm_rast = m$Cm, cnc_rast = m$CNC_Cprot,
                             cnc_layer = "CNC_Cprot", crop = crop_i, fvc = m$FVC)
    x$NNI
  }, error = function(e) { cat("field", fld$field_id, "NNI err:", conditionMessage(e), "\n"); NULL })
  if (is.null(nni)) next
  nni_list[[i]] <- mask(crop(nni, vect(fld)), vect(fld))
}
keep <- !sapply(nni_list, is.null)
tiles <- nni_list[keep]
tmpl <- rast(ext(vect(aoi)), resolution = 10, crs = "EPSG:32632")
farm <- rast(tmpl); values(farm) <- NA_real_
for (t in tiles) farm <- cover(farm, resample(t, tmpl, method = "bilinear"))
names(farm) <- "NNI"; farm <- trim(farm)
v <- values(farm, na.rm = TRUE)
cat(sprintf("farm NNI: %d pixels over %d fields | mean %.2f range %.2f..%.2f\n",
            length(v), sum(keep), mean(v), min(v), max(v)))
print(data.frame(field = aoi$field_id, crop = aoi$X2025_crops, peak = peak_date, got = keep))

lab <- data.frame(st_coordinates(st_centroid(st_geometry(aoi))), lab = paste0("F", aoi$field_id))
p <- ggplot() +
  geom_spatraster(data = farm) +
  geom_sf(data = aoi, fill = NA, color = "grey15", linewidth = 0.35) +
  geom_text(data = lab, aes(X, Y, label = lab), size = 3, fontface = "bold", color = "grey20") +
  scale_fill_gradient2(low = "#b2182b", mid = "#1a9850", high = "#2166ac", midpoint = 1.0,
                       limits = c(0.7, 1.3), oob = scales::squish, na.value = "transparent",
                       name = "NNI  ", breaks = c(0.8, 0.9, 1.0, 1.1, 1.2)) +
  coord_sf(expand = FALSE) +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom", legend.key.width = unit(2.2, "cm"), legend.key.height = unit(0.35, "cm"),
        plot.title = element_text(face = "bold", hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, color = "grey30"), plot.margin = margin(2,2,2,2)) +
  labs(title = "In-season Nitrogen Nutrition Index (NNI), CERZOO farm",
       subtitle = "each field at its seasonal peak canopy. deficient < 0.9  |  optimal 0.9 to 1.1  |  luxury > 1.1")
ggsave(file.path(SP, "fig_nni_farm.png"), p, width = 9, height = 6.2, dpi = 200, bg = "white")
cat("saved fig_nni_farm.png\n")
