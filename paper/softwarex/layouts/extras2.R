# Candidate extra figures X6 (organic + mineral plan), X9 (replacing a coefficient table) and a graphical
# abstract. Run from the package root after fig2_farm.R and fig5_data.R:
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

# ---- X6: organic + mineral plan for P01 (maize 2024), dairy slurry spread at three efficiency levels ----
LV <- c(bassa = "low", media = "medium", alta = "high")
pl <- do.call(rbind, lapply(names(LV), function(l) {
  r <- plan_distribution("Loamy textures", organic_rows = list(list(fertilizer = "Dairy cattle slurry",
                         quantity_t_ha = 30, level = l)))$rows
  data.frame(level = LV[[l]], applied = r$N_kg, eff = r$efficiency_pct, useful = r$N_useful,
             mineral = max(0, Nstar - r$N_useful))
}))
pl$level <- factor(pl$level, levels = LV)
lg <- rbind(data.frame(level = pl$level, part = "Mineral N (urea)", kg = pl$mineral),
            data.frame(level = pl$level, part = "Useful N from slurry", kg = pl$useful))
pa <- ggplot(lg, aes(level, kg, fill = part)) + geom_col(width = 0.6, colour = "grey20", linewidth = 0.15) +
  geom_hline(yintercept = Nstar, linetype = "dashed", linewidth = 0.4) +
  annotate("text", x = 3.45, y = Nstar + 6, label = sprintf("balance dose %.0f", Nstar), hjust = 1,
           size = (BASE - 1) / .pt, family = FONT) +
  geom_text(data = pl, aes(level, useful / 2, label = sprintf("%.0f%%", eff)), inherit.aes = FALSE,
            size = (BASE - 1) / .pt, family = FONT, colour = "white") +
  scale_fill_manual(values = c("Useful N from slurry" = OKABE[[3]], "Mineral N (urea)" = OKABE[[5]]), name = NULL) +
  scale_y_continuous(limits = c(0, 200), expand = expansion(c(0, 0))) +
  labs(x = "Efficiency of the slurry distribution", y = expression("N (kg N ha"^-1*")"),
       subtitle = "30 t/ha dairy slurry = 153 kg N applied (organic limit 170)") +
  theme_sat() + theme(legend.position = "top", plot.subtitle = element_text(size = BASE - 1))
put(pa, "X6_organic_plan", 90, 85)
print(pl)

# ---- X9: the same rotation with the bundled and with an edited uptake table ---------------------------
rot <- read.csv(system.file("extdata/piacenza_p01_rotation.csv", package = "agrinutri"))
dose <- function() vapply(seq_len(nrow(rot)), function(i) { r <- rot[i, ]
  calculate_N_fertilization(N_balance(r$expected_yield_tons_ha, r$crop, r$ccp, sand = p1$sand, clay = p1$clay,
    Ntot = p1$Ntot, SOM = p1$SOM, CN = p1$CN, winter_rain = r$winter_rain, start_spring_rain = r$start_spring_rain,
    prev_crop = r$prev_crop, source = "None", location = p1$location, forg_quantity = 0)) }, numeric(1))
d0 <- dose()
my <- uptake_table; my$N <- my$N * 1.1                                 # illustrative edit: unit N uptake +10 percent
old <- agrinutri_tables(uptake_table = my); d1 <- dose(); agrinutri_tables()
dx <- data.frame(year = rot$year, crop = rot$crop_class, default = d0, edited = d1)
dx$lab <- factor(paste0(dx$year, "\n", sub(" ", "\n", dx$crop)), levels = paste0(dx$year, "\n", sub(" ", "\n", dx$crop)))
code <- c("my <- uptake_table", "my$N <- my$N * 1.1", "agrinutri_tables(uptake_table = my)",
          "N_balance(...)       # every call uses it", "agrinutri_tables()   # bundled tables again")
pc <- ggplot() + annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "grey97", colour = "grey60", linewidth = 0.3) +
  annotate("text", x = 0.04, y = seq(0.85, by = -0.17, length.out = length(code)), label = code, hjust = 0,
           family = "mono", size = (BASE - 1) / .pt) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) + theme_void()
pd <- ggplot(dx, aes(lab)) +
  geom_segment(aes(y = default, yend = edited, xend = lab), colour = "grey55", linewidth = 0.7) +
  geom_point(aes(y = default, colour = "bundled table"), size = 2.2) +
  geom_point(aes(y = edited, colour = "edited table (+10% N uptake)"), size = 2.2) +
  scale_colour_manual(values = c("bundled table" = OKABE[[5]], "edited table (+10% N uptake)" = OKABE[[6]]), name = NULL) +
  labs(x = NULL, y = expression("Balance dose (kg N ha"^-1*")")) + theme_sat() +
  theme(legend.position = "top", axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9))
put(add_tags(pc + pd + plot_layout(widths = c(0.8, 1.6))), "X9_tables", 190, 70)
print(dx[, 1:4])

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
  plot_annotation(title = "agrinutri: an open R engine from the nutrient balance to the variable-rate machine file",
                  theme = theme(plot.title = element_text(size = BASE + 0.5, face = "bold", family = FONT, hjust = 0.5)))
put(ga, "GA_graphical_abstract", 133, 53)
cat("extras2 written\n")
