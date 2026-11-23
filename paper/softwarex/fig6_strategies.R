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
# two-point calibration anchors from the field NDVI (5th and 95th percentile), as in the package vignette
fv0 <- vect(st_transform(field, crs(ndvi)))
q <- quantile(values(mask(ndvi, fv0), na.rm = TRUE), c(0.05, 0.95)); VI_LO <- round(q[[1]], 2); VI_HI <- round(q[[2]], 2)
cat("calibration anchors NDVI", VI_LO, VI_HI, "
")
strip <- function(v, inv = TRUE) build_strip_prescription(field, machine_width = 24, cell_length = 30,
  variability = v, vi_raster = ndvi, nni_raster = nni, n_target = Nstar, min_dose = lo, max_dose = hi,
  vi_low = VI_LO, vi_high = VI_HI, calibration_inverse = inv, preserve_mean = TRUE)
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
block <- function(k, ylab = TRUE) {
  d <- data.frame(x = idx[[XV[[k]]]], dose = M[[k]], area = area)
  rule <- ggplot(d[is.finite(d$x), ], aes(x, dose)) +
    geom_hline(yintercept = Nstar, linetype = "dotted", linewidth = 0.35) +
    { if (XV[[k]] == "NNI") geom_vline(xintercept = c(0.9, 1.1), linewidth = 0.25, colour = "grey55") } +
    { if (grepl("Calibration", k)) {
        inv <- k == "Calibration (inverse)"
        xs <- seq(min(d$x, na.rm = TRUE), max(d$x, na.rm = TRUE), length.out = 100)
        ys <- approx(c(VI_LO, VI_HI), if (inv) c(hi, lo) else c(lo, hi), xs, rule = 2)$y
        list(geom_line(data = data.frame(x = xs, dose = ys), linetype = "dashed", linewidth = 0.4, colour = "grey45"),
             geom_point(data = data.frame(x = c(VI_LO, VI_HI), dose = if (inv) c(hi, lo) else c(lo, hi)),
                        shape = 4, size = 1.6, stroke = 0.6, colour = "grey20"))
      } } +
    geom_point(aes(fill = dose, size = area), shape = 21, colour = "grey35", stroke = 0.15) + DOSE +
    guides(fill = "none") +
    scale_size_area(max_size = 1.3, guide = "none") +
    scale_y_continuous(limits = c(lo - 3, hi + 3), breaks = c(140, 175, 210)) +
    labs(title = SHORT[[k]], subtitle = sprintf("%s; mean %.0f", DRV[[k]], mu[[k]]), x = paste("Cell", XV[[k]]),
         y = if (ylab) expression("N (kg ha"^-1*")") else NULL) +
    theme_sat() + theme(panel.grid.major = element_blank(), plot.title = element_text(face = "bold", size = BASE, margin = margin(b = 0.5)),
                        plot.subtitle = element_text(size = BASE - 1, colour = "grey30", margin = margin(b = 1.5)),
                        axis.title = element_text(size = BASE - 1))
  g <- cells[, "geometry"]; g$dose <- M[[k]]
  map <- ggplot(g) + geom_sf(aes(fill = dose), colour = "white", linewidth = 0.08) +
    geom_sf(data = field, fill = NA, colour = "grey20", linewidth = 0.25) + DOSE +
    coord_sf(datum = NA) + theme_map() + theme(legend.position = "none")
  wrap_elements(full = rule | map + plot_layout(widths = c(1.6, 1)))
}
key <- ggplot(data.frame(x = seq(lo, hi, length.out = 200)), aes(x, 1, fill = x)) + geom_raster() + DOSE +
  annotate("segment", x = Nstar, xend = Nstar, y = 0.5, yend = 1.5, linetype = "dotted", linewidth = 0.4) +
  scale_x_continuous(breaks = c(lo, 160, Nstar, 190, hi), expand = c(0, 0)) +
  labs(x = expression("Prescribed N dose (kg N ha"^-1*"); dotted: balance dose"), y = NULL) +
  theme_sat() + theme(legend.position = "none", axis.text.y = element_blank(), axis.ticks.y = element_blank(),
                      panel.grid = element_blank(), panel.border = element_blank(), plot.tag = element_blank())
blocks <- wrap_plots(Map(block, names(M), seq_along(M) %in% c(1, 3, 5)), ncol = 2)
fig <- blocks / (plot_spacer() | key | plot_spacer()) + plot_layout(heights = c(3, 0.08)) +
  plot_annotation(tag_levels = list(c(sprintf("(%s)", letters[1:6]), "", "", ""))) &   # no tag on the dose bar
  theme(plot.tag = element_text(family = FONT, face = "bold", size = BASE + 1), plot.tag.location = "margin")
save_fig(fig, "fig6_strategies", "double", 140)
