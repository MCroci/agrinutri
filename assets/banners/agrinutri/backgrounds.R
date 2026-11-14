# Backgrounds of the pkgdown banner (1920 x 600 px): real outputs of the package, no text.
#  bg_province.png : 2024 field N dose of the Piacenza plain (piacenza/a03_figure.R data), light
#  bg_dark.png     : the same map on the dark end of the mako palette
#  bg_field.png    : NNI-zone prescription of plot P01 tiled with the farm fields (Figs. 2-3)
# Run from the package root after paper/softwarex/piacenza/a02_balance.R and fig2_farm.R, fig4_data.R.
suppressMessages({ library(sf); library(ggplot2); library(terra) })
OUT <- "assets/banners/agrinutri"
KW <- Sys.getenv("KWASI_DATA", "C:/Users/michele.croci/Desktop/kwasi-data")
tk <- readRDS("paper/softwarex/piacenza/data/tasks.rds")
d <- tk[tk$year == 2024 & is.finite(tk$dose), ]
d <- aggregate(cbind(Nw = dose * weight, weight) ~ i, d, sum); d$dose <- d$Nw / d$weight
f <- st_make_valid(st_read(file.path(KW, "uscita/consegna/crop_maps_shapefiles/crops_15classes.shp"), quiet = TRUE))
f$dose <- NA_real_; f$dose[d$i] <- d$dose
bb <- st_bbox(f); cx <- mean(bb[c(1, 3)]); cy <- mean(bb[c(2, 4)])
h <- (bb[4] - bb[2]) * 1.05; w <- h * 3.2                   # 1920 x 600 window on the plain
win <- coord_sf(xlim = c(cx - w * 0.62, cx + w * 0.38), ylim = c(cy - h / 2, cy + h / 2), expand = FALSE, datum = NA)
mako <- function(...) scale_fill_viridis_c(option = "mako", direction = -1, limits = c(0, 300), oob = scales::squish, ...)
save <- function(p, name, bg) ggsave(file.path(OUT, name), p, width = 1920, height = 600, units = "px", dpi = 150, bg = bg)

save(ggplot(f) + geom_sf(aes(fill = dose), colour = NA) + mako(na.value = "grey88", guide = "none") + win +
       theme_void(), "bg_province.png", "white")
save(ggplot(f) + geom_sf(aes(fill = dose), colour = NA) +
       scale_fill_viridis_c(option = "mako", direction = 1, limits = c(0, 300), oob = scales::squish,
                            na.value = "#1d2b3a", guide = "none") + win +
       theme_void() + theme(plot.background = element_rect(fill = "#0b1520", colour = NA)), "bg_dark.png", "#0b1520")

rx <- st_read("paper/softwarex/data/rs_rx.geojson", quiet = TRUE)
farm_ids <- read.csv("paper/softwarex/data/farm_2024_ids.csv")$id
fb <- st_bbox(st_buffer(f[f$id %in% farm_ids, ], 900)); fx <- mean(fb[c(1, 3)]); fy <- mean(fb[c(2, 4)])
fh <- fb[4] - fb[2]; fw <- fh * 3.2
save(ggplot() + geom_sf(data = f, aes(fill = dose), colour = "white", linewidth = 0.25) +
       geom_sf(data = st_transform(rx, st_crs(f)), aes(fill = dose), colour = "white", linewidth = 0.15) +
       mako(na.value = "grey90", guide = "none") +
       coord_sf(xlim = c(fx - fw * 0.68, fx + fw * 0.32), ylim = c(fy - fh / 2, fy + fh / 2), expand = FALSE, datum = NA) +
       theme_void(), "bg_field.png", "white")
cat("backgrounds written\n")
