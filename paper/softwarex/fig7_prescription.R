# Fig. 7: how the prescription map of plot P01 is built, step by step, on the real data
# (Sentinel-2 L2A of 21 July 2024, balance dose N* = 175 kg N/ha, bounds 140-210).
# Run from the package root after fig7_data.R:  Rscript paper/softwarex/fig7_prescription.R
suppressMessages({ library(terra); library(sf); library(ggplot2); library(patchwork); library(tidyterra) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
D <- "paper/softwarex/data"
Nstar <- read.csv(file.path(D, "farm_2024.csv"))$N_target[1]; lo <- 0.8 * Nstar; hi <- 1.2 * Nstar
field <- st_read(file.path(D, "rs_field_utm.geojson"), quiet = TRUE)
rx    <- st_read(file.path(D, "rs_rx.geojson"), quiet = TRUE)
s2    <- rast(file.path(D, "rs_s2_20240721.tif"))
lai   <- rast(file.path(D, "rs_LAI.tif")); nni <- rast(file.path(D, "rs_NNI.tif"))
fv <- vect(st_transform(field, crs(s2)))
inner <- st_buffer(field, -10)                           # edge_buffer = 10 of fig7_data.R
IN <- geom_sf(data = inner, fill = NA, colour = "grey15", linewidth = 0.25, linetype = "22", inherit.aes = FALSE)

fr <- list(geom_sf(data = field, fill = NA, colour = "grey15", linewidth = 0.3, inherit.aes = FALSE),
           coord_sf(datum = NA, expand = FALSE), theme_map(),
           theme(legend.position = "bottom", legend.key.width = unit(5, "mm"), legend.key.height = unit(1.5, "mm"),
                 plot.title = element_text(size = BASE, face = "bold", hjust = 0, margin = margin(b = 1)),
                 plot.subtitle = element_text(size = BASE - 1, colour = "grey30", hjust = 0, margin = margin(b = 2))))
step <- function(n, t, s) labs(title = sprintf("%d  %s", n, t), subtitle = s)

# 1 natural-colour composite (red, green, blue), stretched
fc <- c(s2[["B04"]], s2[["B03"]], s2[["B02"]]); fc <- mask(fc, fv)
# one stretch for all bands (keeps the colour balance), from the field interior so the bright margin does not set it
v <- values(mask(fc, buffer(fv, -20)), na.rm = TRUE)
q <- quantile(v, c(0.01, 0.99))
for (i in 1:3) fc[[i]] <- clamp((fc[[i]] - q[1]) / (q[2] - q[1]) * 255, 0, 255)
p1 <- ggplot() + geom_spatraster_rgb(data = fc, r = 1, g = 2, b = 3, max_col_value = 255, interpolate = FALSE) + fr +
  step(1, "Sentinel-2 scene", "21 Jul 2024, natural colour")
# 2 LAI
p2 <- ggplot() + geom_spatraster(data = lai) + fr +
  scale_fill_viridis_c(option = "viridis", limits = c(0, 6), na.value = "transparent", name = "LAI") +
  guides(fill = guide_colourbar(title.position = "left", title.vjust = 1)) +
  step(2, "Canopy traits", "GPR retrieval: leaf area index")
# 3 NNI
p3 <- ggplot() + geom_spatraster(data = nni) + fr + fill_NNI(breaks = c(0.6, 1, 1.4)) +
  guides(fill = guide_colourbar(title.position = "left", title.vjust = 1)) +
  IN + step(3, "Nitrogen Nutrition Index", "actual / critical N")
# 4 NNI zones
zn <- as.data.frame(nni, xy = TRUE, na.rm = TRUE); names(zn)[3] <- "NNI"
zn$zone <- cut(zn$NNI, c(-Inf, 0.9, 1.1, Inf), labels = c("deficient", "optimal", "luxury"))
ZC <- c(deficient = "#b2182b", optimal = "#e8e8e8", luxury = "#2166ac")
p4 <- ggplot(zn) + geom_raster(aes(x, y, fill = zone)) + fr + scale_fill_manual(values = ZC, name = NULL) +
  IN + step(4, "NNI zones", "< 0.9, 0.9-1.1, > 1.1")
# 5 machine grid over the zones
p5 <- ggplot(zn) + geom_raster(aes(x, y, fill = zone), alpha = 0.55) +
  geom_sf(data = rx, fill = NA, colour = "black", linewidth = 0.2, inherit.aes = FALSE) + fr +
  scale_fill_manual(values = ZC, name = NULL) + IN + step(5, "Machine grid", "24 m x 30 m cells along the A-B line")
# 6 first doses from the zone of each cell; 7 final doses after the mass balance
rx$zone <- cut(rx$mean_nni, c(-Inf, 0.9, 1.1, Inf), labels = c("deficient", "optimal", "luxury"))
rx$dose0 <- ifelse(is.na(rx$zone), Nstar, c(deficient = hi, optimal = Nstar, luxury = lo)[as.character(rx$zone)])
m0 <- weighted.mean(rx$dose0, rx$area_ha); m1 <- weighted.mean(rx$dose, rx$area_ha)
DOSE <- fill_N(name = expression("kg N ha"^-1), limits = c(lo, hi), breaks = c(lo, Nstar, hi))
cell <- function(v) list(geom_sf(data = rx, aes(fill = .data[[v]]), colour = "white", linewidth = 0.1, inherit.aes = FALSE),
                         DOSE, guides(fill = guide_colourbar(title.position = "left", title.vjust = 1)))
p6 <- ggplot() + cell("dose0") + fr + step(6, "Zone doses", sprintf("210 / 175 / 140; mean %.1f", m0))
p7 <- ggplot() + cell("dose") + fr + step(7, "Mass balance", sprintf("free cells rescaled; mean %.1f = N*", m1))
# 8 the ISOXML task file actually written by export_prescription()
td <- file.path(tempdir(), "TASKDATA"); unlink(td, recursive = TRUE)
export_prescription(rx[, "dose"], td, format = "isoxml")
xmlf <- list.files(td, pattern = "\\.XML$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)[1]
xl <- readLines(xmlf, warn = FALSE); xl <- trimws(unlist(strsplit(paste(xl, collapse = "\n"), "(?<=>)\\s*(?=<)", perl = TRUE)))
xl <- substr(xl[nzchar(xl)], 1, 36)[1:min(9, length(xl))]
p8 <- ggplot() + annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "grey97", colour = "grey60", linewidth = 0.3) +
  annotate("text", x = 0.03, y = seq(0.93, by = -0.1, length.out = length(xl)), label = xl, hjust = 0, vjust = 1,
           family = "mono", size = (BASE - 2) / .pt) +
  annotate("text", x = 0.5, y = 0.04, label = sprintf("%d cells -> TASKDATA.XML", nrow(rx)), size = (BASE - 1) / .pt,
           family = FONT, fontface = "bold") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) + theme_void() +
  theme(plot.title = element_text(size = BASE, face = "bold", margin = margin(b = 1)),
        plot.subtitle = element_text(size = BASE - 1, colour = "grey30", margin = margin(b = 2))) +
  step(8, "Machine file", "export_prescription(format = \"isoxml\")")
fig <- wrap_plots(p1, p2, p3, p4, p5, p6, p7, p8, nrow = 2)
save_fig(fig, "fig7_prescription", "double", 120)
cat("zone mean", round(m0, 1), "-> final mean", round(m1, 1), "| XML:", basename(xmlf), "\n")
