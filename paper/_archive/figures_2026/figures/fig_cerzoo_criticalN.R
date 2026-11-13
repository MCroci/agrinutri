# Critical-N dilution curves with REAL CERZOO data overlaid: per-pixel canopy
# (biomass W, N concentration) from the GPR retrieval, coloured by NNI, on the
# maize/wheat critical curves. Replaces the purely conceptual Figure 3.
suppressMessages({
  pkgload::load_all("C:/Users/michele.croci/Documents/GitHub/NFert", quiet = TRUE)
  library(terra); library(sf); library(ggplot2); library(scales)
})
SP  <- "C:/Users/MICHEL~1.CRO/AppData/Local/Temp/claude/C--Users-michele-croci-Documents-GitHub-NFert/b5b9999e-d385-4c3e-84cf-b776ad94bd7c/scratchpad"
BASE<- "C:/Users/michele.croci/Desktop/presto-deploy/data/rasters/downloads_cerzoo_multiband"
RAW <- "C:/Users/michele.croci/Desktop/presto-deploy/data/raw/cerzoo"
aoi <- st_transform(st_read(file.path(RAW, "aoi_multi_cerzoo_fields.geojson"), quiet = TRUE), 32632)
S2B <- c("B02","B03","B04","B05","B06","B07","B08","B8A","B11","B12")

rows <- list()
for (i in seq_len(nrow(aoi))) {
  fld <- aoi[i, ]; sc <- list.files(file.path(BASE, fld$area_id), pattern = "^S2_.*[.]tif$", full.names = TRUE)
  if (!length(sc)) next
  dt <- regmatches(basename(sc), regexpr("[0-9]{8}", basename(sc)))
  win <- if (grepl("wheat", fld$X2025_crops, ignore.case = TRUE)) 3:6 else 6:9  # crop-specific peak window
  sel <- which(as.integer(substr(dt, 5, 6)) %in% win); if (!length(sel)) next
  best <- NA; bv <- -Inf
  for (j in sel) { rj <- rast(sc[j]); if (nlyr(rj) == 10) names(rj) <- S2B
    nd <- tryCatch(global(compute_vi(rj, "NDVI", scale_factor = 10000), "mean", na.rm = TRUE)[1,1], error = function(e) NA)
    if (is.finite(nd) && nd > bv) { bv <- nd; best <- sc[j] } }
  if (is.na(best)) next
  crop_i <- if (grepl("wheat", fld$X2025_crops, ignore.case = TRUE)) "wheat" else "maize"
  x <- tryCatch({
    m <- estimate_biophysical(raster_path = best, output_dir = tempfile("b", SP),
                              variables = c("LAI","Cm","CNC_Cprot","FVC"), block_rows = 32)
    compute_NNI_from_S2(lai_rast = m$LAI, cm_rast = m$Cm, cnc_rast = m$CNC_Cprot,
                        cnc_layer = "CNC_Cprot", crop = crop_i, fvc = m$FVC)
  }, error = function(e) NULL)
  if (is.null(x)) next
  mk <- vect(fld)
  W <- values(mask(crop(x$W, mk), mk))[,1]
  N <- values(mask(crop(x$N_actual, mk), mk))[,1]
  I <- values(mask(crop(x$NNI, mk), mk))[,1]
  ok <- is.finite(W) & is.finite(N) & is.finite(I)
  if (any(ok)) rows[[length(rows)+1L]] <- data.frame(W = W[ok], N = N[ok], NNI = I[ok], crop = crop_i)
}
df <- do.call(rbind, rows)
cat(sprintf("points: %d | W range %.2f..%.2f | N range %.2f..%.2f | crops: %s\n",
    nrow(df), min(df$W), max(df$W), min(df$N), max(df$N), paste(table(df$crop), collapse="/")))
# subsample for legibility
set.seed(1); if (nrow(df) > 4000) df <- df[sample(nrow(df), 4000), ]

cm <- critical_N_curve("maize"); cw <- critical_N_curve("wheat")
Wg <- seq(1, 12, 0.05)
curv <- rbind(data.frame(W = Wg, Nc = cm$a * Wg^(-cm$b), crop = "maize"),
              data.frame(W = Wg, Nc = cw$a * Wg^(-cw$b), crop = "wheat"))
labels_crop <- c(maize = sprintf("maize (Nc = %.2f W^-%.2f)", cm$a, cm$b),
                 wheat = sprintf("wheat (Nc = %.2f W^-%.2f)", cw$a, cw$b))
df$cropf <- labels_crop[df$crop]; curv$cropf <- labels_crop[curv$crop]

p <- ggplot() +
  geom_point(data = df, aes(W, N, color = NNI), size = 0.5, alpha = 0.45) +
  geom_line(data = curv, aes(W, Nc), color = "black", linewidth = 0.9) +
  facet_wrap(~cropf) +
  scale_color_gradient2(low = "#b2182b", mid = "#1a9850", high = "#2166ac", midpoint = 1.0,
                        limits = c(0.7, 1.3), oob = scales::squish, name = "NNI") +
  scale_x_continuous(limits = c(1, 12)) + scale_y_continuous(limits = c(0, 5)) +
  labs(x = expression("Aboveground biomass W (t DM ha"^-1*")"),
       y = "Canopy N concentration (% DM)",
       title = "Critical-N dilution and CERZOO canopy observations",
       subtitle = "black line: critical curve; points: per-pixel canopy at peak, coloured by NNI") +
  theme_bw(base_size = 12) +
  theme(legend.position = "right", plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(color = "grey30"), strip.background = element_rect(fill = "grey92"))
ggsave(file.path(SP, "fig_criticalN_data.png"), p, width = 9.5, height = 4.8, dpi = 200, bg = "white")
cat("saved fig_criticalN_data.png\n")
