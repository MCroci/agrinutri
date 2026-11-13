# Fig. 4 of the SoftwareX article: regulatory N requirement of the Piacenza plain, 2019-2026.
# (a) N requirement of the mapped fields by crop and year, with the October-January rainfall;
# (b) field dose in 2025. Run from the package root after a02:
#   Rscript paper/softwarex/piacenza/a03_figure.R
suppressMessages({ library(ggplot2); library(patchwork); library(sf) })
source("paper/sat/theme_sat.R")
HERE <- "paper/softwarex/piacenza"
KW <- Sys.getenv("KWASI_DATA", "C:/Users/michele.croci/Desktop/kwasi-data")

bc <- read.csv(file.path(HERE, "data/n_by_crop_year.csv"))
lump <- c("Soft wheat" = "Winter cereals", "Durum wheat" = "Winter cereals", "Barley" = "Winter cereals",
          "Winter cereals" = "Winter cereals", "Maize" = "Maize", "Processing tomato" = "Processing tomato",
          "Meadow" = "Meadows", "Sunflower" = "Other summer crops", "Sorghum" = "Other summer crops",
          "Soybean" = "Other summer crops", "Other summer crops" = "Other summer crops", "Alfalfa" = "Alfalfa")
bc$crop <- factor(lump[bc$group], levels = c("Maize", "Winter cereals", "Processing tomato", "Meadows",
                                              "Other summer crops", "Alfalfa"))
st <- aggregate(N_t ~ year + crop, bc, sum)
rain <- read.csv(file.path(HERE, "data/era5_seasonal.csv"))
rn <- aggregate(precip_mm.ondj ~ crop_year, rain, mean); names(rn) <- c("year", "ondj")
k <- 12000 / 600                                                     # secondary axis: 600 mm = 12 kt
pa <- ggplot(st, aes(factor(year), N_t / 1000, fill = crop)) + geom_col(width = 0.7, colour = "grey20", linewidth = 0.15) +
  geom_line(data = rn, aes(factor(year), ondj * k / 1000, group = 1), inherit.aes = FALSE, linewidth = 0.5) +
  geom_point(data = rn, aes(factor(year), ondj * k / 1000), inherit.aes = FALSE, size = 1) +
  scale_fill_manual(values = unname(OKABE[c(2, 5, 6, 4, 7, 3)]), name = NULL) +
  scale_y_continuous(expand = expansion(c(0, 0.05)), limits = c(0, 13),
                     sec.axis = sec_axis(~ . * 1000 / k, name = "October-January rainfall (mm)")) +
  labs(x = NULL, y = "N requirement of the mapped fields (kt N)") +
  theme_sat() + theme(legend.position = "bottom", legend.key.size = unit(2.5, "mm")) +
  guides(fill = guide_legend(nrow = 2))

tk <- readRDS(file.path(HERE, "data/tasks.rds"))
d25 <- tk[tk$year == 2025 & is.finite(tk$dose), ]
d25 <- aggregate(cbind(Nw = dose * weight, weight) ~ i, d25, sum); d25$dose <- d25$Nw / d25$weight
f <- st_read(file.path(KW, "uscita/consegna/crop_maps_shapefiles/crops_15classes.shp"), quiet = TRUE)
f$dose <- NA_real_; f$dose[d25$i] <- d25$dose
pb <- ggplot(f) + geom_sf(aes(fill = dose), colour = NA) +
  scale_fill_viridis_c(option = "mako", direction = -1, na.value = "grey85", limits = c(0, 300), oob = scales::squish,
                       name = expression("N dose 2025 (kg N ha"^-1*")")) +
  map_furniture(st_bbox(f), len = 10000) + coord_sf(datum = NA, expand = FALSE) + theme_map() + cbar()
save_fig(add_tags(pa + pb + plot_layout(widths = c(1, 1.25))), "fig4_piacenza", "double", 95,
         dir = "paper/softwarex/figures")
