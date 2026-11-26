# Trial: the examples of the article on the CERZOO farm (crop year 2025), with its 10 m soil maps.
# Needs the local presto-deploy data (see paper/sat/00_config.R). Run from the package root:
#   SAT_SCENARIO=season Rscript paper/softwarex/layouts/cerzoo_trial.R
# then fig6_prescription.R and fig7_strategies.R with SWX_DATA=paper/softwarex/data_cerzoo,
# SWX_SCENE=20250613 and SWX_FIGDIR=paper/softwarex/layouts/cerzoo. Outputs stay local (gitignored).
Sys.setenv(SAT_SCENARIO = "season")
source("paper/sat/00_config.R")
suppressMessages({ library(ggplot2); library(patchwork); library(tidyterra) })
source("paper/softwarex/theme_swx.R")
D <- "paper/softwarex/data_cerzoo"; OUT <- "paper/softwarex/layouts/cerzoo"
dir.create(D, FALSE, TRUE); dir.create(OUT, FALSE, TRUE)
FOCUS <- 10; SCENE <- "20250619"                        # largest field; first scene with biomass above 1 t/ha

# ---- soil: 10 m maps -> balance inputs per pixel and per field -------------------------------
soil <- read_soil()
nf <- c(soil$tn * 10, soil$toc * 1.724, soil$clay, soil$sand, soil$toc / soil$tn)
names(nf) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
fm <- terra::extract(nf, vect(AOI), fun = mean, na.rm = TRUE, ID = FALSE)

# ---- farm: one balance per field on the field means, all terms --------------------------------
bal <- do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i) { fi <- FIELDS[i, ]; s <- fm[match(fi$field_id, AOI$field_id), ]
  b <- N_balance(fi$yield, fi$crop, fi$ccp, sand = s$Sand, clay = s$Clay, Ntot = s$TN, SOM = s$SOM, CN = s$CNratio,
                 oxygen_availability = fi$oxygen, winter_rain = fi$winter_rain, start_spring_rain = fi$start_spring_rain,
                 prev_crop = fi$prev_crop, source = "None", location = fi$location, forg_quantity = 0)
  data.frame(field_id = fi$field_id, label = fi$label, crop = sub(" \\(.*| FF.*", "", fi$crop), prev = fi$prev_crop,
             A = b$A, B = -b$B, C = b$C1 + b$C2, D = b$D, E = -b$E, F = -b$F, G = -b$G,
             dose = calculate_N_fertilization(b), mas = get_MAS(fi$crop)$mas_N) }))
bal$area <- as.numeric(st_area(AOI))[match(bal$field_id, AOI$field_id)] / 1e4
print(bal[, c("label", "crop", "prev", "dose", "mas", "area")], digits = 4)
cat("farm total t N:", round(sum(bal$dose * bal$area) / 1000, 2), "over", round(sum(bal$area), 1), "ha\n")

# ---- pixel: the same balance on every 10 m pixel of the soil maps ------------------------------
N <- rast(soil[[1]]); values(N) <- NA; names(N) <- "N"
for (i in seq_len(nrow(FIELDS))) { fi <- FIELDS[i, ]
  d <- spatial_N_balance(mask(nf, soil$field == fi$field_id, maskvalues = FALSE), expected_yield_tons_ha = fi$yield,
        crop = fi$crop, ccp = fi$ccp, oxygen_availability = fi$oxygen, winter_rain = fi$winter_rain,
        start_spring_rain = fi$start_spring_rain, prev_crop = fi$prev_crop, source = "None", forg_quantity = 0,
        location = fi$location, terms = "N_to_apply")[[1]]
  N <- cover(N, d) }
N <- trim(N)                                             # the soil maps cover more than the farm
px <- terra::extract(N, vect(AOI), ID = TRUE); rng <- tapply(px[, 2], px$ID, function(v) diff(range(v, na.rm = TRUE)))
cat("within-field range of the pixel dose (kg N/ha):", round(rng), "\n")

# ---- trial figure T1: farm map, terms per field, pixel dose -------------------------------------
A2 <- merge(AOI[, "field_id"], bal, by = "field_id"); ctr <- st_coordinates(st_centroid(st_geometry(A2)))
lim <- range(c(bal$dose, values(N)), na.rm = TRUE); lim <- c(floor(lim[1] / 10) * 10, ceiling(lim[2] / 10) * 10)
pa <- ggplot(A2) + geom_sf(aes(fill = dose), colour = "grey20", linewidth = 0.2) +
  geom_sf(data = A2[A2$dose > A2$mas, ], fill = NA, colour = OKABE[[6]], linewidth = 0.9) +
  annotate("label", x = ctr[, 1], y = ctr[, 2], label = sprintf("%s\n%.0f", A2$label, A2$dose), size = (BASE - 1.5) / .pt,
           family = FONT, lineheight = 0.85, fill = alpha("white", 0.75), label.padding = unit(0.6, "mm")) +
  fill_N(name = expression("Balance dose (kg N ha"^-1*")"), limits = lim) + cbar() + coord_sf(datum = NA) + theme_map() +
  theme(legend.position = "bottom")
lg <- reshape(bal[, c("label", "crop", "prev", TERMS)], direction = "long", varying = TERMS, v.names = "kg", timevar = "term",
              times = TERMS, idvar = "label")
lg$term <- factor(lg$term, levels = TERMS)
lab <- setNames(sprintf("%s  %s\nafter %s", bal$label, bal$crop, tolower(sub("Maize stalks buried", "maize", sub(" in good conditions", "", bal$prev)))), bal$label)
lg$lab <- factor(lab[lg$label], levels = rev(lab)); bal$lab <- factor(lab[bal$label], levels = rev(lab))
pb <- ggplot(lg, aes(kg, lab, fill = term)) + geom_col(width = 0.7, colour = "grey20", linewidth = 0.1) +
  geom_vline(xintercept = 0, linewidth = 0.4) +
  geom_point(data = bal, aes(dose, lab, shape = "Balance dose"), inherit.aes = FALSE, fill = "white", size = 1.5, stroke = 0.4) +
  geom_point(data = bal, aes(mas, lab, shape = "Crop maximum dose"), inherit.aes = FALSE, colour = OKABE[[6]], size = 1.6, stroke = 0.6) +
  scale_fill_manual(values = TERM_FILL, name = NULL, guide = guide_legend(nrow = 1, order = 1)) +
  scale_shape_manual(values = c("Balance dose" = 23, "Crop maximum dose" = 4), name = NULL) +
  labs(x = expression("Balance term (kg N ha"^-1*"): supplies (-) | demand, losses (+)"), y = NULL) +
  theme_sat() + theme(legend.position = "top", legend.box = "vertical", legend.spacing.y = unit(0, "mm"),
                      legend.key.size = unit(2.5, "mm"), axis.text.y = element_text(size = BASE - 1.5, lineheight = 0.85))
pc <- ggplot() + geom_spatraster(data = N) + geom_sf(data = AOI, fill = NA, colour = "grey20", linewidth = 0.2) +
  fill_N(name = expression("Pixel dose, 10 m (kg N ha"^-1*")"), limits = lim) + cbar() + coord_sf(datum = NA) + theme_map() +
  theme(legend.position = "bottom")
save_fig(add_tags((pa | pc) / pb + plot_layout(heights = c(1, 1))) & theme(plot.tag.location = "margin"), "T1_farm_pixel", "double", 185, dir = OUT)

# ---- data of the focus field for fig6_prescription.R and fig7_strategies.R --------------------
S2B <- c("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12")
f <- AOI[AOI$field_id == FOCUS, ]; fa <- FIELDS[FIELDS$field_id == FOCUS, ]
sc <- list.files(file.path(S2, fa$area_id), pattern = paste0("^S2_", SCENE), full.names = TRUE)[1]
s2 <- rast(sc); names(s2) <- S2B
s2f <- file.path(D, paste0("rs_s2_", SCENE, ".tif")); writeRaster(s2, s2f, overwrite = TRUE)
bio <- estimate_biophysical(s2f, output_dir = tempfile("bio"), variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot", crop = "maize", fvc = bio$FVC)
Nstar <- min(bal$dose[bal$field_id == FOCUS], bal$mas[bal$field_id == FOCUS])   # the crop maximum dose sets the plan
rx <- build_strip_prescription(f, machine_width = 24, cell_length = 30, variability = "nni", nni_raster = nni$NNI,
                               n_target = Nstar, min_dose = 0.8 * Nstar, max_dose = 1.2 * Nstar, edge_buffer = 10)
fv <- vect(st_transform(f, crs(bio$LAI)))
writeRaster(nni$NNI, file.path(D, "rs_NNI_full.tif"), overwrite = TRUE)
writeRaster(mask(crop(bio$LAI, fv), fv), file.path(D, "rs_LAI.tif"), overwrite = TRUE)
writeRaster(mask(crop(nni$NNI, fv), fv), file.path(D, "rs_NNI.tif"), overwrite = TRUE)
wr <- function(x, n) st_write(x, file.path(D, n), delete_dsn = TRUE, quiet = TRUE)
wr(st_transform(rx, crs(bio$LAI)), "rs_rx.geojson"); wr(st_transform(f, crs(bio$LAI)), "rs_field_utm.geojson")
wr(st_transform(f, 4326), "rs_field.geojson")
write.csv(data.frame(plot = "P01", N_target = Nstar), file.path(D, "farm_2024.csv"), row.names = FALSE)  # name read by the figure scripts
v <- values(mask(crop(nni$NNI, fv), fv), na.rm = TRUE)
cat("focus F", FOCUS, " N* ", round(Nstar, 1), " | NNI pixels ", length(v), " median ", round(median(v), 2),
    " zones:", sum(v < 0.9), sum(v >= 0.9 & v <= 1.1), sum(v > 1.1),
    " | LAI median ", round(median(values(mask(crop(bio$LAI, fv), fv), na.rm = TRUE)), 2), "\n", sep = "")
cat("cells", nrow(rx), "doses:", paste(names(table(rx$dose)), table(rx$dose), sep = "x", collapse = "  "),
    "| mean", round(weighted.mean(rx$dose, rx$area_ha), 1), "\n")
