# Fig. 5: within-field strategies on plot P01 (Figs. 2-4), all redistributing the balance dose N*
#     of P01 on the same 24 m x 30 m cells: uniform, calibration ramp (inverse, direct), NDVI quantile classes, NNI zones,
#     Holland-Schepers sufficiency index (variable_rate_N).
# Run from the package root after fig2_farm.R and fig4_data.R:  Rscript paper/softwarex/fig5_strategies.R
suppressMessages({ library(terra); library(sf); library(ggplot2); library(patchwork) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
D <- "paper/softwarex/data"

fm <- read.csv(file.path(D, "farm_2024.csv"), stringsAsFactors = FALSE)

# ---- within field P01 ---------------------------------------------------------------------
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
M <- list("Uniform" = cells$dose,
          "Calibration (inverse)" = strip("calibration", TRUE)$dose,
          "Calibration (direct)" = strip("calibration", FALSE)$dose,
          "NDVI quantile classes" = strip("classes", TRUE)$dose,
          "NNI zones" = strip("nni")$dose,
          "Holland-Schepers" = zonal(hs_r))
mm <- do.call(rbind, lapply(names(M), function(k) {
  g <- cells[, "geometry"]; g$dose <- M[[k]]; g$method <- k; g }))
mu <- sapply(M, function(x) weighted.mean(x, as.numeric(st_area(cells))))
lv <- sprintf("%s (mean %.0f)", names(M), mu)
mm$method <- factor(sprintf("%s (mean %.0f)", mm$method, mu[mm$method]), levels = lv)
summ <- aggregate(dose ~ method, cbind(st_drop_geometry(mm), a = as.numeric(st_area(mm))),
                  function(x) round(c(min = min(x), max = max(x)), 1))
cat("N* P01:", Nstar, "\n"); print(summ)
write.csv(data.frame(method = names(M), t(sapply(M, function(x) c(min = min(x), max = max(x),
          mean = weighted.mean(x, as.numeric(st_area(cells))))))), file.path(D, "methods_p01.csv"), row.names = FALSE)

mm$diff <- mm$dose - Nstar
pb <- ggplot(mm) + geom_sf(aes(fill = diff), colour = "white", linewidth = 0.1) +
  geom_sf(data = field, fill = NA, colour = "grey20", linewidth = 0.25) +
  facet_wrap(~method, ncol = 3) +
  scale_fill_gradient2(low = "#1b7837", mid = "#f7f7f7", high = "#762a83", midpoint = 0,
                       limits = c(lo, hi) - Nstar, oob = scales::squish,
                       name = expression("Dose minus balance dose (kg N ha"^-1*")")) +
  coord_sf(datum = NA) + theme_map() + cbar() +
  theme(strip.text = element_text(size = BASE - 1, margin = margin(b = 1)))
mm$area <- as.numeric(st_area(mm))
mm$m0 <- factor(sub(" [(]mean.*", "", mm$method), levels = names(M))
pc <- ggplot(st_drop_geometry(mm), aes(dose, m0, weight = area)) +
  geom_vline(xintercept = Nstar, linetype = "dotted", linewidth = 0.4) +
  geom_boxplot(width = 0.55, outlier.size = 0.4, linewidth = 0.3, fill = "grey92") +
  scale_y_discrete(limits = rev(names(M))) +
  labs(x = expression("Cell dose (kg N ha"^-1*"); dotted: balance dose"), y = NULL) + theme_sat()
save_fig(add_tags(pc / pb + plot_layout(heights = c(0.55, 1.5))), "fig5_strategies", "double", 140)
