# Fig. 3: plot P01 (the maize field of Figs. 2, 4 and 5) through the rotation 2019-2026.
# (a) N balance terms, dose and MAS per year; (b) P2O5 and K2O doses per year; (c, d) Olsen P and
# exchangeable K inside the field on the regional 100 m grid (continuous; DPI classes printed to the console).
# Crop class per year from the satellite crop maps (previous crop: class of the year before),
# soil from the regional maps 0-30 cm, rainfall from ERA5, yields from ISTAT Piacenza.
# Run from the package root after piacenza/a01_inputs.R:  Rscript paper/softwarex/fig3_p01_years.R
suppressMessages({ library(sf); library(terra); library(ggplot2); library(patchwork); library(tidyterra) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
P <- "paper/softwarex/piacenza"; D <- "paper/softwarex/data"; FOCUS <- 5336; YEARS <- 2019:2026
SOIL <- Sys.getenv("RER_SOIL", file.path("C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
                   "rds/research/8. db-and-layer-soil-meteo-limits/soil-properties/rer"))
fld  <- readRDS(file.path(P, "data/fields.rds")); s <- fld[fld$id == FOCUS, ]
cmap <- read.csv(file.path(P, "crop_map.csv"), stringsAsFactors = FALSE)
rain <- read.csv(file.path(P, "data/era5_seasonal.csv"))
ist  <- read.csv(file.path(P, "data/istat_piacenza_raw.csv"), stringsAsFactors = FALSE)
yl <- function(code, crop, y) {
  a <- ist$OBS_VALUE[ist$TYPE_OF_CROP == code & ist$TIME_PERIOD == y & ist$DATA_TYPE == "ART"]
  q <- ist$OBS_VALUE[ist$TYPE_OF_CROP == code & ist$TIME_PERIOD == y & ist$DATA_TYPE == "HP_Q_EXT"]
  if (length(a) && length(q)) q / a / 10 else uptake_table$reference_yield[uptake_table$crop == crop][1]
}
cls <- setNames(unlist(s[paste0("c", YEARS)]), YEARS)

rows <- lapply(YEARS, function(y) {
  cl <- cls[[as.character(y)]]; m <- cmap[cmap$class == cl, ]
  if (!nrow(m)) return(data.frame(year = y, class = cl, crop = NA))
  pv <- if (y > min(YEARS)) cmap$prev_crop[cmap$class == cls[[as.character(y - 1)]]] else character()
  r <- rain[rain$cell == s$cell & rain$crop_year == y, ]
  yld <- yl(m$istat, m$dpi_crop, y)
  b <- N_balance(expected_yield_tons_ha = yld, crop = m$dpi_crop, ccp = m$ccp, sand = s$sand, clay = s$clay,
                 Ntot = s$ntot, SOM = s$corg * 1.724, CN = s$corg * 10 / s$ntot, oxygen_availability = "Normal",
                 winter_rain = r$precip_mm.ondj, start_spring_rain = r$precip_mm.feb,
                 prev_crop = if (length(pv)) pv[1] else "Undefined", source = "None",
                 fertorg_frequency = "every year", location = "Isolated plain", forg_quantity = 0)
  pb <- P_balance(yld, m$dpi_crop, olsen_value = s$olsen_p, olsen_unit = "P", clay = s$clay, sand = s$sand)
  kb <- K_balance(yld, m$dpi_crop, k_value = s$k_exch, k_unit = "K", clay = s$clay, sand = s$sand)
  data.frame(year = y, class = cl, crop = m$dpi_crop, yield = yld, rain = r$precip_mm.ondj,
             A = b$A, C = b$C1 + b$C2, D = b$D, B = -b$B, E = -b$E, F = -b$F, G = -b$G,
             N = calculate_N_fertilization(b), MAS = get_MAS(m$dpi_crop)$mas_N,
             P2O5 = pb$P2O5_required, K2O = kb[[grep("K2O_required|K2O", names(kb), value = TRUE)[1]]])
})
yr <- do.call(rbind, lapply(rows, function(x) { for (k in setdiff(names(rows[[1]]), names(x))) x[[k]] <- NA; x[names(rows[[1]])] }))
write.csv(yr, file.path(D, "p01_years.csv"), row.names = FALSE)
print(yr[, c("year", "class", "yield", "rain", "N", "MAS", "P2O5", "K2O")])

# ---- within-field P and K on the regional grid --------------------------------------------
field <- st_read(file.path(D, "rs_field.geojson"), quiet = TRUE)
pk <- c(rast(file.path(SOIL, "npk_0_30/Fosforo_P_assimilabile/P_0_30.tif")),
        rast(file.path(SOIL, "npk_0_30/Potassio_K_scambiabile/K_0_30.tif")))
names(pk) <- c("P", "K")
fv <- vect(st_transform(field, crs(pk)))
pk <- mask(crop(pk, fv, snap = "out"), fv, touches = TRUE)
grp <- calc_soil_group_and_id_rag(s$clay, s$sand)
pv <- values(pk); ok <- complete.cases(pv)
pcl <- vapply(pv[ok, "P"], function(v) as.character(classify_P_olsen(v, unit = "P")$rating), "")
kcl <- vapply(pv[ok, "K"], function(v) as.character(classify_K(v, unit = "K", soil_group = grp$soil.group)$rating), "")
cat("pixels", sum(ok), "| P", round(range(pv[ok, "P"]), 1), "| K", round(range(pv[ok, "K"]), 0), "\n")
print(table(P = pcl)); print(table(K = kcl))

# ---- figure ---------------------------------------------------------------------------------
EN <- c("mais" = "Maize", "cereali vernini" = "Winter cereals", "prato e medica" = "Alfalfa",
        "pomodoro" = "Processing tomato", "altre estive" = "Other summer crops")   # 2026: 9-class names
yr$name <- ifelse(yr$class %in% names(EN), EN[yr$class], yr$class)
yr$lab <- ifelse(is.na(yr$crop), paste0(yr$year, "\n(no estimate)"), paste0(yr$year, "\n", sub(" ", "\n", yr$name)))  # long names on two lines
yr$lab <- factor(yr$lab, levels = yr$lab)
tl <- reshape(yr[!is.na(yr$crop), c("lab", "A", "C", "D", "B", "E", "F", "G")], direction = "long",
              varying = c("A", "C", "D", "B", "E", "F", "G"), v.names = "kg",
              timevar = "term", times = c("A", "C", "D", "B", "E", "F", "G"), idvar = "lab")
tl$term <- factor(tl$term, levels = c("A", "C", "D", "B", "E", "F", "G"))
TERM <- c(A = OKABE[[5]], C = OKABE[[3]], D = OKABE[[2]], B = OKABE[[4]], E = OKABE[[7]], F = OKABE[[8]], G = "grey60")
pa <- ggplot(tl, aes(lab, kg, fill = term)) + geom_col(width = 0.65, colour = "grey20", linewidth = 0.15) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_errorbar(data = yr[!is.na(yr$crop), ], aes(lab, ymin = MAS, ymax = MAS), inherit.aes = FALSE,
                width = 0.7, linewidth = 0.6, colour = OKABE[[6]]) +
  geom_point(data = yr[!is.na(yr$crop), ], aes(lab, N), inherit.aes = FALSE, shape = 23, fill = "white", size = 1.8) +
  scale_fill_manual(values = TERM, name = NULL) + scale_x_discrete(drop = FALSE) +
  labs(x = NULL, y = expression("N balance term (kg N ha"^-1*")")) +
  theme_sat() + theme(legend.position = "top", axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9)) +
  guides(fill = guide_legend(nrow = 1))
pkd <- reshape(yr[!is.na(yr$crop), c("lab", "P2O5", "K2O")], direction = "long", varying = c("P2O5", "K2O"),
               v.names = "kg", timevar = "nutrient", times = c("P[2]*O[5]", "K[2]*O"), idvar = "lab")
pb <- ggplot(pkd, aes(lab, kg, fill = nutrient)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7, colour = "grey20", linewidth = 0.15) +
  scale_fill_manual(values = c("P[2]*O[5]" = OKABE[[7]], "K[2]*O" = OKABE[[1]]), labels = scales::parse_format(), name = NULL) +
  scale_x_discrete(drop = FALSE, limits = levels(yr$lab)) + scale_y_continuous(expand = expansion(c(0, 0.05))) +
  labs(x = NULL, y = expression("Dose (kg ha"^-1*")")) +
  theme_sat() + theme(legend.position = "top", axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9))
fr <- list(geom_sf(data = st_transform(field, crs(pk)), fill = NA, colour = "grey20", linewidth = 0.4),
           coord_sf(datum = NA, expand = FALSE), theme_map(), cbar())
pc <- ggplot() + geom_spatraster(data = pk[["P"]]) + fr +
  scale_fill_viridis_c(option = "mako", direction = -1, na.value = "transparent", name = "Olsen P (mg/kg)")
pd <- ggplot() + geom_spatraster(data = pk[["K"]]) + fr +
  scale_fill_viridis_c(option = "rocket", direction = -1, na.value = "transparent", name = "Exchangeable K (mg/kg)")
save_fig(add_tags((pa | pb) / (pc | pd) + plot_layout(heights = c(1.1, 1))), "fig3_p01_years", "double", 140)
