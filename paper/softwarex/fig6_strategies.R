# Fig. 6: precision-agriculture methods on plot P01 (Figs. 2-5): for each method the rule (cell dose against the
#     driving layer) and the prescription map; all redistribute the balance dose N* on the same 24 m x 30 m cells.
#     (a) input layers NDVI and NNI and the dose scale; (b-g) uniform, calibration ramps, NDVI classes, NNI zones, sufficiency index.
# Run from the package root after fig2_farm.R and fig5_data.R:  Rscript paper/softwarex/fig6_strategies.R
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
VI_LO <- 0.35; VI_HI <- 0.80                              # package defaults, replaced below
strip <- function(v, inv = TRUE) build_strip_prescription(field, machine_width = 24, cell_length = 30,
  variability = v, vi_raster = ndvi, nni_raster = nni, n_target = Nstar, min_dose = lo, max_dose = hi,
  vi_low = VI_LO, vi_high = VI_HI, calibration_inverse = inv, preserve_mean = TRUE)
cells <- strip("uniform")
# two-point calibration anchors symmetric around the area-weighted mean cell NDVI: the line passes
# through (mean NDVI, N*), so its field mean is already the balance dose and the rescaling only
# corrects the cells clipped at the bounds; half-width = half the 5th-95th percentile range of cell NDVI
ndvi_cell <- terra::extract(ndvi, vect(st_transform(cells, crs(ndvi))), fun = mean, na.rm = TRUE, ID = FALSE)[, 1]
m  <- weighted.mean(ndvi_cell, as.numeric(st_area(cells)), na.rm = TRUE)
hw <- diff(quantile(ndvi_cell, c(0.05, 0.95), na.rm = TRUE)) / 2
VI_LO <- round(m - hw, 2); VI_HI <- round(m + hw, 2)
cat("mean cell NDVI", round(m, 3), "| calibration anchors", VI_LO, VI_HI, "
")
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
          "Holland-Schepers" = .preserve_mean(zonal(hs_r), as.numeric(st_area(cells)), Nstar, lo, hi))  # cell means rescaled like the pixels
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

# ---- figure: precision-agriculture methods, the rule of each method and the map it produces ------------
SHORT <- c("Uniform" = "Uniform rate", "Calibration (inverse)" = "Calibration ramp, inverse",
           "Calibration (direct)" = "Calibration ramp, direct", "NDVI quantile classes" = "Quantile classes",
           "NNI zones" = "NNI management zones", "Holland-Schepers" = "Sufficiency index")
DRV <- c("Uniform" = "one dose, no sensing", "Calibration (inverse)" = "more N where NDVI is low",
         "Calibration (direct)" = "more N where NDVI is high", "NDVI quantile classes" = "five NDVI classes",
         "NNI zones" = "deficient / optimal / luxury", "Holland-Schepers" = "Holland-Schepers curve on NDVI")
XV <- c("Uniform" = "NDVI", "Calibration (inverse)" = "NDVI", "Calibration (direct)" = "NDVI",
        "NDVI quantile classes" = "NDVI", "NNI zones" = "NNI", "Holland-Schepers" = "NDVI")
cellmean <- function(r) terra::extract(r, vect(st_transform(cells, crs(r))), fun = mean, na.rm = TRUE, ID = FALSE)[, 1]
idx <- list(NDVI = cellmean(ndvi), NNI = cellmean(nni))
area <- as.numeric(st_area(cells))
DOSE <- fill_N(name = NULL, limits = c(lo, hi))
COL  <- scale_colour_viridis_c(option = "mako", direction = -1, limits = c(lo, hi), guide = "none")
TIT <- c("Uniform" = "Uniform", "Calibration (inverse)" = "Ramp, inverse", "Calibration (direct)" = "Ramp, direct",
         "NDVI quantile classes" = "Quantile classes", "NNI zones" = "NNI zones", "Holland-Schepers" = "Sufficiency index")
rule_plot <- function(k, first = FALSE) {
  d <- data.frame(x = idx[[XV[[k]]]], dose = M[[k]], area = area)
  ggplot(d[is.finite(d$x), ], aes(x, dose)) +
    geom_hline(yintercept = Nstar, linetype = "dotted", linewidth = 0.3) +
    { if (XV[[k]] == "NNI") geom_vline(xintercept = c(0.9, 1.1), linewidth = 0.25, colour = "grey55") } +
    { if (grepl("Calibration", k)) {
        inv <- k == "Calibration (inverse)"
        xs <- seq(min(d$x, na.rm = TRUE), max(d$x, na.rm = TRUE), length.out = 100)
        ys <- approx(c(VI_LO, VI_HI), if (inv) c(hi, lo) else c(lo, hi), xs, rule = 2)$y
        CAL <<- list(geom_line(data = data.frame(x = xs, dose = ys), linetype = "dashed", linewidth = 0.5, colour = OKABE[[6]]),
             geom_point(data = data.frame(x = c(VI_LO, VI_HI), dose = if (inv) c(hi, lo) else c(lo, hi)),
                        shape = 4, size = 1.5, stroke = 0.7, colour = OKABE[[6]]))
        NULL
      } else { CAL <<- NULL; NULL } } +
    geom_point(aes(fill = dose, size = area), shape = 21, colour = "grey35", stroke = 0.12) + DOSE + CAL +
    guides(fill = "none") + scale_size_area(max_size = 1, guide = "none") +
    scale_y_continuous(limits = c(lo - 3, hi + 3), breaks = c(140, 175, 210)) +
    { if (XV[[k]] == "NDVI") scale_x_continuous(limits = c(0.3, 0.98), breaks = c(0.4, 0.6, 0.8))
      else scale_x_continuous(breaks = c(0.6, 0.9, 1.1)) } +
    labs(title = TIT[[k]], subtitle = sprintf("mean %.0f", mu[[k]]), x = XV[[k]],
         y = if (first) expression("Cell dose (kg N ha"^-1*")") else NULL) +
    theme_sat() + theme(panel.grid.major = element_blank(),
                        plot.title = element_text(face = "bold", size = BASE - 0.5, margin = margin(b = 0)),
                        plot.subtitle = element_text(size = BASE - 1.5, colour = "grey30", margin = margin(b = 1)),
                        axis.title = element_text(size = BASE - 0.5), axis.text = element_text(size = BASE - 1),
                        axis.text.y = if (first) element_text(size = BASE - 1) else element_blank(),
                        axis.ticks.length = unit(0.6, "mm"), plot.margin = margin(1, 1.5, 1, 1.5))
}
map_plot <- function(k) {
  g <- cells[, "geometry"]; g$dose <- M[[k]]
  ggplot(g) + geom_sf(aes(fill = dose), colour = "white", linewidth = 0.05) +
    geom_sf(data = field, fill = NA, colour = "grey20", linewidth = 0.2) + DOSE +
    coord_sf(datum = NA, expand = FALSE) + theme_map() + theme(legend.position = "none", plot.margin = margin(0, 1, 0, 1))
}
key <- ggplot(data.frame(x = seq(lo, hi, length.out = 200)), aes(x, 1, fill = x)) + geom_raster() + DOSE +
  annotate("segment", x = Nstar, xend = Nstar, y = 0.5, yend = 1.5, linetype = "dotted", linewidth = 0.4) +
  scale_x_continuous(breaks = c(lo, 160, Nstar, 190, hi), expand = c(0, 0)) +
  labs(x = expression("Prescribed N dose (kg N ha"^-1*"); dotted: balance dose N*"), y = NULL) +
  theme_sat() + theme(legend.position = "none", axis.text.y = element_blank(), axis.ticks.y = element_blank(),
                      panel.grid = element_blank(), panel.border = element_blank(), plot.tag = element_blank())
grid <- wrap_plots(c(Map(rule_plot, names(M), seq_along(M) == 1), lapply(names(M), map_plot)),
                   nrow = 2, byrow = TRUE, heights = c(1, 1))
fig <- grid / (plot_spacer() | key | plot_spacer()) + plot_layout(heights = c(2.1, 0.08)) +
  plot_annotation(tag_levels = list(c(sprintf("(%s)", letters[1:6]), rep("", 9)))) &   # tags on the rules only
  theme(plot.tag = element_text(family = FONT, face = "bold", size = BASE + 1))
save_fig(fig, "fig6_strategies", "double", 90)
