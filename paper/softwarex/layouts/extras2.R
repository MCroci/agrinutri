# Graphical abstract (the former candidates X6 and X9 are now fig5_organic.R and fig9_tables.R). Run from the package root after fig3_farm.R and fig7_data.R:
#   Rscript paper/softwarex/layouts/extras2.R
suppressMessages({ library(sf); library(terra); library(ggplot2); library(patchwork); library(tidyterra) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
OUT <- "paper/softwarex/layouts"; D <- "paper/softwarex/data"
put <- function(p, name, w, h) ggsave(file.path(OUT, paste0(name, ".png")), p, device = ragg::agg_png,
                                      width = w, height = h, units = "mm", dpi = 300, bg = "white")
farm <- st_read(system.file("extdata/piacenza_farm.geojson", package = "agrinutri"), quiet = TRUE)
p1 <- farm[farm$plot == "P01", ]
Nstar <- farm_balance(farm)$N_target[farm$plot == "P01"]

# ---- graphical abstract (Elsevier: about 13 x 5 cm) ----------------------------------------------------
nni <- rast(file.path(D, "rs_NNI.tif")); rx <- st_read(file.path(D, "rs_rx.geojson"), quiet = TRUE)
fu <- st_read(file.path(D, "rs_field_utm.geojson"), quiet = TRUE)
tt <- function(t) theme(plot.title = element_text(size = BASE - 0.5, face = "bold", hjust = 0.5))
g1 <- ggplot(farm) + geom_sf(fill = "grey85", colour = "grey30", linewidth = 0.2) +
  geom_sf(data = p1, fill = OKABE[[5]], colour = "grey20", linewidth = 0.3) + coord_sf(datum = NA) + theme_void() +
  labs(title = "Fields, soil, weather") + tt()
g2 <- ggplot() + annotate("text", x = 0.5, y = 0.62, label = "N = A - B + C + D
- E - F - G", size = (BASE - 0.5) / .pt, lineheight = 0.9,
                          family = FONT, fontface = "bold", colour = OKABE[[5]]) +
  annotate("text", x = 0.5, y = 0.32, label = sprintf("N* = %.0f kg N/ha\nalso P and K", Nstar), size = (BASE - 1) / .pt,
           family = FONT, lineheight = 0.9) + xlim(0, 1) + ylim(0, 1) + theme_void() + labs(title = "Nutrient balance") + tt()
g3 <- ggplot() + geom_spatraster(data = nni) + geom_sf(data = fu, fill = NA, colour = "grey20", linewidth = 0.2) +
  fill_NNI() + coord_sf(datum = NA, expand = FALSE) + theme_void() + theme(legend.position = "none") +
  labs(title = "Sentinel-2 NNI") + tt()
g4 <- ggplot(rx) + geom_sf(aes(fill = dose), colour = "white", linewidth = 0.05) +
  fill_N(limits = c(0.8, 1.2) * Nstar) + coord_sf(datum = NA, expand = FALSE) + theme_void() +
  theme(legend.position = "none") + labs(title = "Prescription, mean = N*") + tt()
g5 <- ggplot() + annotate("rect", xmin = 0.15, xmax = 0.85, ymin = 0.2, ymax = 0.8, fill = "grey95", colour = "grey40") +
  annotate("text", x = 0.5, y = 0.5, label = "ISOXML\nShapefile\nJohn Deere\nTrimble", size = (BASE - 1.5) / .pt,
           family = "mono", lineheight = 0.9) + xlim(0, 1) + ylim(0, 1) + theme_void() + labs(title = "Machine file") + tt()
ar <- ggplot() + annotate("text", x = 0.5, y = 0.45, label = "→", size = 14 / .pt, colour = "grey40") +
  xlim(0, 1) + ylim(0, 1) + theme_void()
ga <- (g1 | ar | g2 | ar | g3 | ar | g4 | ar | g5) + plot_layout(widths = c(1, 0.18, 1.1, 0.18, 1, 0.18, 1, 0.18, 0.9)) +
  plot_annotation(title = "agrinutri: from nutrient balances to variable-rate fertiliser prescriptions",
                  theme = theme(plot.title = element_text(size = BASE + 0.5, face = "bold", family = FONT, hjust = 0.5)))
put(ga, "GA_graphical_abstract", 133, 53)
cat("extras2 written\n")
