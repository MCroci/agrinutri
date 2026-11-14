# Fig. 4: from a Sentinel-2 scene to a prescription on field P01 of the Fig. 2 farm (13 August
# 2024), house style of theme_swx.R. Run from the package root after fig4_data.R:
#   Rscript paper/softwarex/fig4_rs.R
suppressMessages({ library(terra); library(sf); library(ggplot2); library(patchwork); library(tidyterra) })
source("paper/softwarex/theme_swx.R")
D <- "paper/softwarex/data"
field <- st_read(file.path(D, "rs_field_utm.geojson"), quiet = TRUE)
rx    <- st_read(file.path(D, "rs_rx.geojson"), quiet = TRUE)
Nstar <- read.csv(file.path(D, "farm_2024.csv"))$N_target[1]   # balance dose of P01: dose bounds 80-120 %
lai <- rast(file.path(D, "rs_LAI.tif")); names(lai) <- "LAI"
nni <- rast(file.path(D, "rs_NNI.tif")); names(nni) <- "NNI"
lai <- mask(lai, vect(field), touches = FALSE); nni <- mask(nni, vect(field), touches = FALSE)
bb <- st_bbox(field)
fr <- list(geom_sf(data = field, fill = NA, colour = "grey20", linewidth = 0.3),
           coord_sf(datum = NA, expand = FALSE), theme_map(), cbar())
pa <- ggplot() + geom_spatraster(data = lai) + fr + map_furniture(bb, len = 100) +
  scale_fill_viridis_c(option = "viridis", limits = c(0, 6), na.value = "transparent",
                       name = expression("Leaf area index (m"^2*" m"^-2*")"))
pb <- ggplot() + geom_spatraster(data = nni) + fr + fill_NNI(breaks = c(0.6, 0.9, 1, 1.1, 1.4))
pc <- ggplot(rx) + geom_sf(aes(fill = dose), colour = "white", linewidth = 0.15) + fr +
  fill_N(name = expression("N dose (kg N ha"^-1*")"), limits = c(0.8, 1.2) * Nstar)
save_fig(add_tags(pa + pb + pc), "fig4_rs_prescription", "double", 75)
