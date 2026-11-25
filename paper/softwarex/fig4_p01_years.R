# Fig. 4: plot P01 (Figs. 2 and 4-6) through the rotation 2019-2026.
# N balance terms, dose and maximum dose per year, with the October-January rainfall under each crop.
# Crop class per year from the satellite crop maps (previous crop: class of the year before),
# soil from the regional maps 0-30 cm, rainfall from ERA5, yields from ISTAT Piacenza.
# Run from the package root after piacenza/a01_inputs.R:  Rscript paper/softwarex/fig4_p01_years.R
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
  data.frame(year = y, class = cl, crop = m$dpi_crop, ccp = m$ccp, prev_crop = if (length(pv)) pv[1] else "Undefined",
             yield = yld, rain = r$precip_mm.ondj, spring_rain = r$precip_mm.feb,
             A = b$A, C = b$C1 + b$C2, D = b$D, B = -b$B, E = -b$E, F = -b$F, G = -b$G,
             N = calculate_N_fertilization(b), MAS = get_MAS(m$dpi_crop)$mas_N,
             P2O5 = pb$P2O5_required, K2O = kb[[grep("K2O_required|K2O", names(kb), value = TRUE)[1]]])
})
yr <- do.call(rbind, lapply(rows, function(x) { for (k in setdiff(names(rows[[1]]), names(x))) x[[k]] <- NA; x[names(rows[[1]])] }))
write.csv(yr, file.path(D, "p01_years.csv"), row.names = FALSE)
print(yr[, c("year", "class", "yield", "rain", "N", "MAS", "P2O5", "K2O")])

# ---- figure ---------------------------------------------------------------------------------
EN <- c("mais" = "Maize", "cereali vernini" = "Winter cereals", "prato e medica" = "Alfalfa",
        "pomodoro" = "Processing tomato", "altre estive" = "Other summer crops")   # 2026: 9-class names
yr$name <- ifelse(yr$class %in% names(EN), EN[yr$class], yr$class)
yr$lab <- ifelse(is.na(yr$crop), paste0(yr$year, "\n(no estimate)"), paste0(yr$year, "\n", sub(" ", "\n", yr$name), "\n", round(yr$rain), " + ", round(yr$spring_rain), " mm"))  # crop, Oct-Jan + Feb rain
yr$lab <- factor(yr$lab, levels = yr$lab)
tl <- reshape(yr[!is.na(yr$crop), c("lab", "A", "C", "D", "B", "E", "F", "G")], direction = "long",
              varying = c("A", "C", "D", "B", "E", "F", "G"), v.names = "kg",
              timevar = "term", times = c("A", "C", "D", "B", "E", "F", "G"), idvar = "lab")
tl$term <- factor(tl$term, levels = c("A", "C", "D", "B", "E", "F", "G"))
yk <- yr[!is.na(yr$crop), ]
pa <- ggplot(tl, aes(lab, kg, fill = term)) + geom_col(width = 0.65, colour = "grey20", linewidth = 0.15) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_errorbar(data = yk, aes(lab, ymin = MAS, ymax = MAS, colour = "Crop maximum dose"), inherit.aes = FALSE,
                width = 0.7, linewidth = 0.6) +
  geom_point(data = yk, aes(lab, N, shape = "Balance dose"), inherit.aes = FALSE, fill = "white", size = 1.8) +
  fill_terms(nrow = 7) + scale_x_discrete(drop = FALSE) +
  scale_colour_manual(values = c("Crop maximum dose" = OKABE[[6]]), name = NULL, guide = guide_legend(order = 3)) +
  scale_shape_manual(values = c("Balance dose" = 23), name = NULL, guide = guide_legend(order = 2)) +
  coord_cartesian(ylim = c(-130, 310)) +
  annotate("text", x = nlevels(yr$lab), y = -128, label = sprintf("G = %.0f", -yk$G[nrow(yk)]), vjust = 0, size = (BASE - 1.5) / .pt, family = FONT, colour = "white") +
  labs(x = NULL, y = expression("N balance term (kg N ha"^-1*")")) +
  theme_sat() + theme(legend.position = "right", legend.box = "vertical", legend.spacing.y = unit(0, "mm"),
                      legend.margin = margin(0, 0, 0, 0), legend.key.size = unit(2.5, "mm"),
                      axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9))
save_fig(pa + theme(legend.position = "top") + guides(fill = guide_legend(nrow = 2)), "fig4_p01_years", "double", 90)
