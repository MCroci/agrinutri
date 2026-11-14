# Fig. 2: farm balance with farm_balance() (diamonds: balance dose; crosses: dose_standard_N()) on a farm of satellite-delineated fields of the
# Piacenza plain (the nearest field of each crop around plot P01), crop year 2024.
# Inputs per field as in Section 3.4: crop class 2024 (previous crop: class 2023), regional soil
# maps 0-30 cm, ERA5 rainfall, ISTAT yields 2024. Run from the package root after
# piacenza/a01_inputs.R:  Rscript paper/softwarex/fig2_farm.R
suppressMessages({ library(sf); library(ggplot2); library(patchwork) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
P <- "paper/softwarex/piacenza"
KW <- Sys.getenv("KWASI_DATA", "C:/Users/michele.croci/Desktop/kwasi-data")
Y <- 2024; FOCUS <- 5336    # plot P01: crop known in every year 2019-2026 (Figs. 3-5)

fld  <- readRDS(file.path(P, "data/fields.rds"))
cmap <- read.csv(file.path(P, "crop_map.csv"), stringsAsFactors = FALSE)
geo  <- st_read(file.path(KW, "uscita/consegna/crop_maps_shapefiles/crops_15classes.shp"), quiet = TRUE)
geo  <- st_make_valid(geo)                                  # rings with inverted winding in the shapefile
geo  <- cbind(geo[, "id"], fld[match(geo$id, fld$id), setdiff(names(fld), "id")])
ok   <- geo$c2024 %in% cmap$class & geo$c2023 %in% cmap$class & geo$c2024 != "Maize (silage)"
ctr  <- suppressWarnings(st_point_on_surface(st_geometry(geo)))
d    <- as.numeric(st_distance(ctr, ctr[geo$id == FOCUS]))
farm <- geo[ok, ][order(d[ok])[1:20], ]
farm$plot <- sprintf("P%02d", seq_len(nrow(farm)))

ist <- read.csv(file.path(P, "data/istat_piacenza_raw.csv"), stringsAsFactors = FALSE)
yl  <- function(code, crop) {
  a <- ist$OBS_VALUE[ist$TYPE_OF_CROP == code & ist$TIME_PERIOD == Y & ist$DATA_TYPE == "ART"]
  q <- ist$OBS_VALUE[ist$TYPE_OF_CROP == code & ist$TIME_PERIOD == Y & ist$DATA_TYPE == "HP_Q_EXT"]
  if (length(a) && length(q)) q / a / 10 else uptake_table$reference_yield[uptake_table$crop == crop][1]
}
rain <- read.csv(file.path(P, "data/era5_seasonal.csv"))
r <- rain[match(paste(farm$cell, Y), paste(rain$cell, rain$crop_year)), ]
cm <- cmap[match(farm$c2024, cmap$class), ]
pv <- cmap$prev_crop[match(farm$c2023, cmap$class)]
farm$crop <- cm$dpi_crop; farm$ccp <- cm$ccp
farm$expected_yield_tons_ha <- mapply(yl, cm$istat, cm$dpi_crop)
farm$prev_crop <- ifelse(is.na(pv), "Undefined", pv)
farm$Ntot <- farm$ntot; farm$SOM <- farm$corg * 1.724; farm$CN <- farm$corg * 10 / farm$ntot
farm$oxygen_availability <- "Normal"; farm$winter_rain <- r$precip_mm.ondj; farm$start_spring_rain <- r$precip_mm.feb
farm$source <- "None"; farm$fertorg_frequency <- "every year"; farm$location <- "Isolated plain"
farm$forg_quantity <- 0; farm$area_ha <- farm$ha
out <- farm_balance(farm)
stopifnot(all(is.na(out$balance_error)))
# keep the nearest field of each crop, at most five (fields of the same crop repeat the same balance)
out <- head(out[!duplicated(out$c2024), ], 5)
out$plot <- sprintf("P%02d", seq_len(nrow(out)))
stopifnot(out$id[1] == FOCUS)

args <- c("expected_yield_tons_ha", "crop", "ccp", "sand", "clay", "Ntot", "SOM", "CN",
          "oxygen_availability", "winter_rain", "start_spring_rain", "prev_crop", "source",
          "fertorg_frequency", "location", "forg_quantity")
terms <- do.call(rbind, lapply(seq_len(nrow(out)), function(i) {
  b <- do.call(N_balance, as.list(st_drop_geometry(out)[i, args]))
  data.frame(plot = out$plot[i], A = b$A, C = b$C1 + b$C2, D = b$D, B = -b$B, E = -b$E, F = -b$F, G = -b$G)
}))
write.csv(cbind(st_drop_geometry(out)[, c("plot", "c2024", "c2023", "area_ha", "expected_yield_tons_ha",
                                          "N_target", "MAS_cap", "MAS_ok", "N_total_kg")], terms[, -1]),
          "paper/softwarex/data/farm_2024.csv", row.names = FALSE)
write.csv(data.frame(id = out$id), "paper/softwarex/data/farm_2024_ids.csv", row.names = FALSE)
saveRDS(as.list(st_drop_geometry(out)[out$plot == "P01", args]), "paper/softwarex/data/p01_inputs.rds")  # for Figs. 4-5
st_write(out[out$plot == "P01", c("ha", "c2024")], "paper/softwarex/data/rs_field.geojson",   # boundary of P01 for Figs. 3-5
         delete_dsn = TRUE, quiet = TRUE)
cat("farm ha", round(sum(out$area_ha), 1), "| N total kg", round(sum(out$N_total_kg)),
    "| over MAS:", paste(out$plot[!out$MAS_ok], collapse = ", "), "\n")

# ---- figure ------------------------------------------------------------------------------
lab <- st_drop_geometry(out)[, c("plot", "c2024", "c2023")]
lab$name <- paste0(lab$plot, " ", lab$c2024)
bb <- st_bbox(out); ctx <- geo[lengths(st_intersects(geo, st_as_sfc(bb))) > 0 & !geo$id %in% out$id, ]
pa <- ggplot(out) + geom_sf(data = ctx, fill = "grey90", colour = "white", linewidth = 0.2) +   # neighbouring fields
  geom_sf(aes(fill = N_target), colour = "grey20", linewidth = 0.2) +
  geom_sf(data = out[!out$MAS_ok, ], fill = NA, colour = OKABE[[6]], linewidth = 0.8) +
  geom_sf_label(aes(label = plot), size = (BASE - 1) / .pt, family = FONT, linewidth = 0,
                fill = alpha("white", 0.8), label.padding = unit(0.4, "mm")) +
  fill_N(name = expression("Mineral N dose (kg N ha"^-1*")"), limits = c(0, 300)) +
  map_furniture(bb, len = 200) + coord_sf(xlim = bb[c(1, 3)], ylim = bb[c(2, 4)], datum = NA) + theme_map() + cbar()
tl <- reshape(terms, direction = "long", varying = c("A", "C", "D", "B", "E", "F", "G"), v.names = "kg",
              timevar = "term", times = c("A", "C", "D", "B", "E", "F", "G"), idvar = "plot")
tl$term <- factor(tl$term, levels = c("A", "C", "D", "B", "E", "F", "G"))
tl$plot <- factor(tl$plot, levels = rev(lab$plot)); lab$plot <- factor(lab$plot, levels = rev(lab$plot))
dose <- data.frame(plot = factor(out$plot, levels = levels(tl$plot)), N = out$N_target,
                   std = vapply(out$crop, function(cr) dose_standard_N(cr)$dose_final, numeric(1)))
pb <- ggplot(tl, aes(kg, plot, fill = term)) + geom_col(width = 0.65, colour = "grey20", linewidth = 0.15) +
  geom_vline(xintercept = 0, linewidth = 0.3) +
  geom_point(data = dose, aes(N, plot), inherit.aes = FALSE, shape = 23, fill = "white", size = 1.6) +
  geom_point(data = dose, aes(std, plot), inherit.aes = FALSE, shape = 4, size = 1.4, stroke = 0.6, colour = OKABE[[6]]) +
  scale_fill_manual(values = c(A = OKABE[[5]], C = OKABE[[3]], D = OKABE[[2]], B = OKABE[[4]],
                               E = OKABE[[7]], F = OKABE[[8]], G = "grey60"), name = NULL) +
  scale_y_discrete(labels = setNames(paste0(lab$plot, "  ", lab$c2024, "
after ", tolower(lab$c2023)), lab$plot)) +
  labs(x = expression("Balance term (kg N ha"^-1*"): supplies (-) | demand and losses (+)"), y = NULL) +
  theme_sat() + theme(legend.position = "top", legend.key.size = unit(2.5, "mm")) +
  guides(fill = guide_legend(nrow = 1))
save_fig(add_tags(pa + pb + plot_layout(widths = c(1, 1.15))), "fig2_farm", "double", 72)
