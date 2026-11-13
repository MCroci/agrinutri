# Fig. 4: every rate-setting method of the package on the same farm and field.
# (a) Field level, the eight plots of Fig. 2 (2024): regulatory balance dose (calculate_N_fertilization),
#     standard dose (dose_standard_N) and crop maximum (MAS).
# (b-h) Within field, plot P01 (Fig. 3), all redistributing the balance dose N* of P01 on the same
#     24 m x 30 m cells: uniform, calibration ramp (inverse, direct), NDVI quantile classes, NNI zones,
#     Holland-Schepers sufficiency index (variable_rate_N), QUEFTS economic optimum (optimize_VR_DPI).
# Run from the package root after fig2_farm.R and fig3_data.R:  Rscript paper/softwarex/fig4_methods.R
suppressMessages({ library(terra); library(sf); library(ggplot2); library(patchwork) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
D <- "paper/softwarex/data"
cmap <- read.csv("paper/softwarex/piacenza/crop_map.csv", stringsAsFactors = FALSE)

# ---- (a) field level -------------------------------------------------------------------
fm <- read.csv(file.path(D, "farm_2024.csv"), stringsAsFactors = FALSE)
fm$dpi <- cmap$dpi_crop[match(fm$c2024, cmap$class)]
fm$standard <- vapply(fm$dpi, function(cr) dose_standard_N(cr)$dose_final, numeric(1))
fl <- rbind(data.frame(plot = fm$plot, method = "DPI balance", N = fm$N_target),
            data.frame(plot = fm$plot, method = "Standard dose", N = fm$standard))
fm$lab <- factor(paste0(fm$plot, "  ", fm$c2024), levels = rev(paste0(fm$plot, "  ", fm$c2024)))
fl$lab <- fm$lab[match(fl$plot, fm$plot)]
pa <- ggplot(fl, aes(N, lab)) +
  geom_point(data = fm, aes(MAS_cap, lab), inherit.aes = FALSE, shape = 124, size = 4, colour = OKABE[[6]]) +
  geom_point(aes(shape = method, fill = method), size = 1.8) +
  scale_shape_manual(values = c("DPI balance" = 21, "Standard dose" = 24), name = NULL) +
  scale_fill_manual(values = c("DPI balance" = OKABE[[5]], "Standard dose" = OKABE[[2]]), name = NULL) +
  labs(x = expression("Field dose (kg N ha"^-1*"); vertical bar: MAS"), y = NULL) +
  theme_sat() + theme(legend.position = "top")

# ---- (b-h) within field P01 ---------------------------------------------------------------------
field <- st_read(file.path(D, "rs_field.geojson"), quiet = TRUE)
inp   <- readRDS(file.path(D, "p01_inputs.rds"))
Nstar <- fm$N_target[fm$plot == "P01"]; lo <- 0.8 * Nstar; hi <- 1.2 * Nstar
s2  <- rast(file.path(D, "rs_s2_20240813.tif"))
ndvi <- (s2[["B08"]] - s2[["B04"]]) / (s2[["B08"]] + s2[["B04"]]); names(ndvi) <- "NDVI"
nni <- rast(file.path(D, "rs_NNI_full.tif"))
strip <- function(v, inv = TRUE) build_strip_prescription(field, machine_width = 24, cell_length = 30,
  variability = v, vi_raster = ndvi, nni_raster = nni, n_target = Nstar, min_dose = lo, max_dose = hi,
  calibration_inverse = inv, preserve_mean = TRUE)
cells <- strip("uniform")
zonal <- function(r) {                                   # pixel prescription -> cell means, field mean kept
  cv <- st_transform(cells, crs(r))
  z <- terra::extract(r, vect(cv), fun = mean, na.rm = TRUE, ID = FALSE)[, 1]
  z[!is.finite(z)] <- mean(z, na.rm = TRUE)
  z
}
hs <- variable_rate_N(ndvi, n_dose = Nstar, method = "holland", minN = lo, maxN = hi)
hs_r <- hs$rate_raster
QF <- file.path(D, "rs_quefts.tif")                      # slow (one QUEFTS optimisation per pixel): cached
if (!file.exists(QF)) {
  qf <- optimize_VR_DPI(field_inputs = inp, crop_params = "Mais da granella (classe 700)",   # QUEFTS table uses the Italian name
                        NNI_raster = crop(nni, vect(st_transform(field, crs(nni)))))
  writeRaster(qf$N_prescription, QF, overwrite = TRUE)
}
qf_r <- rast(QF)
M <- list("Uniform" = cells$dose,
          "Calibration (inverse)" = strip("calibration", TRUE)$dose,
          "Calibration (direct)" = strip("calibration", FALSE)$dose,
          "NDVI quantile classes" = strip("classes", TRUE)$dose,
          "NNI zones" = strip("nni")$dose,
          "Holland-Schepers" = zonal(hs_r),
          "QUEFTS economic optimum" = zonal(qf_r))
mm <- do.call(rbind, lapply(names(M), function(k) {
  g <- cells[, "geometry"]; g$dose <- M[[k]]; g$method <- k; g }))
mu <- sapply(M, function(x) weighted.mean(x, as.numeric(st_area(cells))))
lv <- sprintf("%s (mean %.0f)", names(M), mu)
mm$method <- factor(sprintf("%s (mean %.0f)", mm$method, mu[mm$method]), levels = lv)
summ <- aggregate(dose ~ method, cbind(st_drop_geometry(mm), a = as.numeric(st_area(mm))),
                  function(x) round(c(min = min(x), max = max(x)), 1))
cat("N* P01:", Nstar, "\n"); print(summ)
cat("QUEFTS field mean:", round(weighted.mean(M[[7]], as.numeric(st_area(cells))), 1), "
")
write.csv(data.frame(method = names(M), t(sapply(M, function(x) c(min = min(x), max = max(x),
          mean = weighted.mean(x, as.numeric(st_area(cells))))))), file.path(D, "methods_p01.csv"), row.names = FALSE)
write.csv(fm[, c("plot", "c2024", "N_target", "standard", "MAS_cap")], file.path(D, "methods_farm.csv"), row.names = FALSE)

pb <- ggplot(mm) + geom_sf(aes(fill = dose), colour = "white", linewidth = 0.1) +
  geom_sf(data = field, fill = NA, colour = "grey20", linewidth = 0.25) +
  facet_wrap(~method, ncol = 4) +
  fill_N(name = expression("N dose (kg N ha"^-1*")"), limits = c(0, 250)) +
  coord_sf(datum = NA) + theme_map() + cbar() +
  theme(strip.text = element_text(size = BASE - 1, margin = margin(b = 1)))
save_fig(add_tags(pa + pb + plot_layout(ncol = 1, heights = c(0.8, 1.6))), "fig4_methods", "double", 150)
