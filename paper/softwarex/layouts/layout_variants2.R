# More layout alternatives (E, F) of Figs. 2-6 and four candidate extra figures (X1-X4).
# Run from the package root after layouts/layout_variants.R:  Rscript paper/softwarex/layouts/layout_variants2.R
suppressMessages({ library(ggplot2); library(patchwork); library(sf); library(terra) })
options(swx.nosave = TRUE)
pkgload::load_all(".", quiet = TRUE)
OUT <- "paper/softwarex/layouts"
run <- function(f) { e <- new.env(); source(file.path("paper/softwarex", f), local = e); e }
put <- function(p, name, w, h) ggsave(file.path(OUT, paste0(name, ".png")), p, device = ragg::agg_png,
                                      width = w, height = h, units = "mm", dpi = 300, bg = "white")
mt <- theme(plot.tag.location = "margin")

# ---- Fig. 2 E, F ---------------------------------------------------------------------------
e <- run("fig3_farm.R")
dd <- reshape(e$dose, idvar = "plot", timevar = "type", direction = "wide")
names(dd) <- c("plot", "balance", "standard")
dd$lab <- e$lab$name[match(dd$plot, e$lab$plot)]
pE <- ggplot(dd, aes(y = plot)) +
  geom_segment(aes(x = standard, xend = balance, yend = plot), colour = "grey60", linewidth = 0.8) +
  geom_point(aes(x = standard, colour = "Standard dose"), size = 2.4) +
  geom_point(aes(x = balance, colour = "Balance dose"), size = 2.4) +
  scale_colour_manual(values = c("Balance dose" = OKABE[[5]], "Standard dose" = OKABE[[6]]), name = NULL) +
  scale_y_discrete(labels = setNames(paste0(e$lab$plot, "  ", e$lab$c2024), as.character(e$lab$plot))) +
  labs(x = expression("N dose (kg N ha"^-1*")"), y = NULL) + theme_sat() + theme(legend.position = "top")
put(add_tags(e$pa + pE + plot_layout(widths = c(1, 1.3))), "fig2_E", 190, 72)
ord <- e$tl; ordN <- e$dose[e$dose$type == "Balance dose", ]
ord$plot <- factor(ord$plot, levels = as.character(ordN$plot[order(ordN$N)]))
put(add_tags(e$pa + (e$pb %+% ord) + plot_layout(widths = c(1, 1.3))), "fig2_F", 190, 72)

# ---- Fig. 3 E, F ---------------------------------------------------------------------------
e <- run("fig4_p01_years.R"); yk <- e$yk
pE <- ggplot(yk, aes(lab)) +
  geom_col(aes(y = N, fill = "Balance dose"), width = 0.6) +
  geom_errorbar(aes(ymin = MAS, ymax = MAS, colour = "Crop maximum dose"), width = 0.7, linewidth = 0.7) +
  geom_line(aes(y = rain / 2, group = 1, linetype = "Oct-Jan rainfall"), colour = "grey30", linewidth = 0.4) +
  geom_point(aes(y = rain / 2), colour = "grey30", size = 1.2) +
  scale_fill_manual(values = c("Balance dose" = OKABE[[5]]), name = NULL) +
  scale_colour_manual(values = c("Crop maximum dose" = OKABE[[6]]), name = NULL) +
  scale_linetype_manual(values = c("Oct-Jan rainfall" = "solid"), name = NULL) +
  scale_y_continuous(name = expression("N (kg N ha"^-1*")"), sec.axis = sec_axis(~ . * 2, name = "Rainfall (mm)"),
                     expand = expansion(c(0, 0.05))) +
  labs(x = NULL) + theme_sat() + theme(legend.position = "top", axis.text.x = element_text(lineheight = 0.9))
put(pE, "fig3_E", 190, 80)
pF <- ggplot(e$tl, aes(lab, term, fill = kg)) + geom_tile(colour = "white") +
  geom_text(aes(label = round(kg)), size = (BASE - 1) / .pt, family = FONT) +
  scale_fill_gradient2(low = OKABE[[4]], mid = "white", high = OKABE[[5]], midpoint = 0, name = "kg N/ha") +
  scale_y_discrete(limits = rev(TERMS), labels = TERM_LAB) + labs(x = NULL, y = NULL) +
  theme_sat() + theme(panel.grid = element_blank(), axis.text.x = element_text(lineheight = 0.9))
put(pF, "fig3_F", 190, 75)

# ---- Fig. 4 E, F ---------------------------------------------------------------------------
e <- run("fig5_pk.R")
cont <- function(v, name, opt) ggplot(e$px) + geom_raster(aes(x, y, fill = .data[[v]])) +
  geom_sf(data = e$fo, fill = NA, colour = "black", linewidth = 0.35, inherit.aes = FALSE) +
  geom_sf(data = e$p1, fill = NA, colour = "black", linewidth = 0.9, inherit.aes = FALSE) +
  scale_fill_viridis_c(option = opt, direction = -1, name = name) + coord_sf(datum = NA, expand = FALSE) +
  theme_map() + cbar()
put(add_tags(e$pb / (cont("olsen_p", "Olsen P (mg/kg P)", "mako") | cont("k_exch", "Exchangeable K (mg/kg K)", "rocket")) +
             plot_layout(heights = c(0.8, 1))) & mt, "fig4_E", 190, 150)
one <- function(nu) ggplot(e$yd[e$yd$nutrient == nu, ], aes(lab, kg)) +
  geom_col(fill = e$NUT[[nu]], width = 0.65, colour = "grey20", linewidth = 0.15) +
  scale_y_continuous(limits = c(0, 310), expand = expansion(c(0, 0.02))) +
  labs(x = NULL, y = parse(text = paste0(nu, "~(kg~ha^-1)"))) + theme_sat() +
  theme(axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9))
put(add_tags((one("P[2]*O[5]") | e$pc) / (one("K[2]*O") | e$pd) + plot_layout(widths = c(1.7, 1))) & mt,
    "fig4_F", 190, 150)

# ---- Fig. 5 E, F ---------------------------------------------------------------------------
e <- run("fig5_rs.R")
zn <- as.data.frame(e$nni, xy = TRUE, na.rm = TRUE)
zn$zone <- cut(zn$NNI, c(-Inf, 0.9, 1.1, Inf), labels = c("deficient", "optimal", "luxury"))
pz <- ggplot(zn) + geom_raster(aes(x, y, fill = zone)) + e$fr +
  scale_fill_manual(values = c(deficient = "#b2182b", optimal = "#f0f0f0", luxury = "#2166ac"), name = "NNI zone") +
  guides(fill = guide_legend(title.position = "top"))
put(add_tags(e$pa + e$pb + pz), "fig5_E", 190, 75)
ph <- ggplot(zn, aes(NNI)) + geom_histogram(aes(fill = zone), binwidth = 0.02, boundary = 0.9, colour = "white", linewidth = 0.1) +
  geom_vline(xintercept = c(0.9, 1.1), linetype = "dashed", linewidth = 0.3) +
  scale_fill_manual(values = c(deficient = "#b2182b", optimal = "grey70", luxury = "#2166ac"), name = NULL) +
  labs(x = "Nitrogen Nutrition Index", y = "Pixels") + theme_sat() + theme(legend.position = "top")
put(add_tags(e$pb + ph + plot_layout(widths = c(1, 1.2))), "fig5_F", 160, 75)

# ---- Fig. 6 E, F ---------------------------------------------------------------------------
e <- run("fig7_strategies.R"); nm <- names(e$M)
dm <- function(k) { g <- e$cells[, "geometry"]; g$d <- e$M[[k]] - e$Nstar
  ggplot(g) + geom_sf(aes(fill = d), colour = "white", linewidth = 0.05) +
    geom_sf(data = e$field, fill = NA, colour = "grey20", linewidth = 0.2) +
    scale_fill_gradient2(low = "#1b7837", mid = "#f7f7f7", high = "#762a83", limits = c(-35, 35),
                         name = expression("Dose minus N* (kg N ha"^-1*")")) +
    labs(title = e$TIT[[k]]) + coord_sf(datum = NA, expand = FALSE) + theme_map() + cbar() +
    theme(plot.title = element_text(size = BASE, face = "bold", hjust = 0.5)) }
put(wrap_plots(lapply(nm, dm), ncol = 3, guides = "collect") & theme(legend.position = "bottom"), "fig6_E", 190, 140)
mp <- function(k) e$map_plot(k) + labs(title = e$TIT[[k]], subtitle = sprintf("mean %.0f", e$mu[[k]])) +
  theme(plot.title = element_text(size = BASE, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = BASE - 1, hjust = 0.5, colour = "grey30"))
put(wrap_plots(lapply(nm, mp), ncol = 3) / (plot_spacer() | e$key | plot_spacer()) + plot_layout(heights = c(2, 0.1)),
    "fig6_F", 190, 150)

# ---- extra figures -----------------------------------------------------------------------------
source("paper/softwarex/theme_swx.R")
farm <- st_read(system.file("extdata/piacenza_farm.geojson", package = "agrinutri"), quiet = TRUE)
p1 <- farm[farm$plot == "P01", ]
# X1: balance per pixel on the regional soil maps (every pixel as the maize of P01, 2024)
rer <- rast(system.file("extdata/rer_soil_piacenza.tif", package = "agrinutri"))
soil <- c(rer[["ntot"]], rer[["corg"]] * 1.724, rer[["clay"]], rer[["sand"]], rer[["corg"]] * 10 / rer[["ntot"]])
names(soil) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
px <- spatial_N_balance(soil, expected_yield_tons_ha = p1$expected_yield_tons_ha, crop = p1$crop, ccp = p1$ccp,
        winter_rain = p1$winter_rain, start_spring_rain = p1$start_spring_rain, prev_crop = p1$prev_crop,
        source = "None", location = p1$location, forg_quantity = 0)
fo <- st_transform(farm, crs(rer))
mk <- function(r, name, pal, lim = NULL) ggplot() + tidyterra::geom_spatraster(data = r) +
  geom_sf(data = fo, fill = NA, colour = "black", linewidth = 0.35) +
  scale_fill_viridis_c(option = pal, direction = -1, na.value = "transparent", name = name, limits = lim) +
  map_furniture(st_bbox(rer), len = 1000) + coord_sf(datum = NA, expand = FALSE) + theme_map() + cbar()
put(add_tags(mk(rer[["clay"]], "Clay (%)", "rocket") + mk(rer[["corg"]] * 1.724, "Organic matter (%)", "viridis") +
             mk(px[["N_to_apply"]], expression("Balance dose, maize (kg N ha"^-1*")"), "mako")), "X1_pixel_balance", 190, 75)
# X2: the province (already produced by piacenza/a03_figure.R)
file.copy("paper/softwarex/figures/piacenza_2019_2026.png", file.path(OUT, "X2_province.png"), overwrite = TRUE)
# X3: sensitivity of the balance dose to October-January rainfall and expected yield (maize, soil of P01)
g <- expand.grid(rain = seq(150, 550, 20), yield = seq(5, 13, 0.4))
g$N <- mapply(function(r, y) calculate_N_fertilization(N_balance(y, p1$crop, p1$ccp, sand = p1$sand, clay = p1$clay,
          Ntot = p1$Ntot, SOM = p1$SOM, CN = p1$CN, winter_rain = r, start_spring_rain = p1$start_spring_rain,
          prev_crop = p1$prev_crop, source = "None", location = p1$location, forg_quantity = 0)), g$rain, g$yield)
px3 <- ggplot(g, aes(rain, yield, fill = N)) + geom_raster() +
  geom_contour(aes(z = N), colour = "white", linewidth = 0.3, breaks = seq(100, 350, 25)) +
  geom_contour(aes(z = N), colour = OKABE[[6]], linewidth = 0.8, breaks = get_MAS(p1$crop)$mas_N) +
  annotate("point", x = p1$winter_rain, y = p1$expected_yield_tons_ha, shape = 23, fill = "white", size = 2.5) +
  annotate("text", x = p1$winter_rain + 12, y = p1$expected_yield_tons_ha, label = "P01 2024", hjust = 0,
           size = BASE / .pt, family = FONT, colour = "white") +
  fill_N(name = expression("Balance dose (kg N ha"^-1*")")) + scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + labs(x = "October-January rainfall (mm)", y = expression("Expected yield (t ha"^-1*")"),
  caption = "white: 25 kg contours; orange: crop maximum dose") + theme_sat() + theme(legend.position = "right")
put(px3, "X3_sensitivity", 140, 90)
# X4: computing time against the number of fields (farm_balance on replicated plots)
n <- c(10, 100, 1000, 5000)
tm <- sapply(n, function(k) { f <- farm[rep(seq_len(nrow(farm)), length.out = k), ]
  system.time(farm_balance(f))[["elapsed"]] })
px4 <- ggplot(data.frame(n, tm), aes(n, tm)) + geom_line() + geom_point(size = 2) +
  geom_text(aes(label = sprintf("%.1f s", tm)), vjust = -1, size = (BASE - 1) / .pt, family = FONT) +
  scale_x_log10() + scale_y_log10() + labs(x = "Fields (farm_balance, one core)", y = "Elapsed time (s)") + theme_sat()
put(px4, "X4_runtime", 90, 70)
cat("runtime:", paste(n, round(tm, 2), sep = ":", collapse = "  "), "\n")
cat("more variants and extras written\n")
