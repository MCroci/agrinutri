# Figures 2 to 7 and Supplementary Figures S1, S2 of the SAT paper, in the house style of
# theme_sat.R (Figure 1 is fig1_architecture.py). Run after 01 to 04 and 06, from the package root:
#   Rscript paper/sat/05_figures.R        Output: paper/sat/figures/*.png and *.pdf
suppressMessages({ library(terra); library(sf); library(tidyterra) })
source("paper/sat/theme_sat.R")
OUT <- "paper/sat/out"; DAT <- "paper/sat/data"
dir.create("paper/sat/figures", FALSE, TRUE)
RAW <- Sys.getenv("PRESTO_DEPLOY", "C:/Users/michele.croci/Desktop/presto-deploy")
aoi <- st_transform(st_read(file.path(RAW, "data/raw/cerzoo/aoi_multi_cerzoo_fields.geojson"), quiet = TRUE), 32632)
aoi$lab <- paste0("F", aoi$field_id)
bb <- st_bbox(aoi)
fields <- geom_sf(data = aoi, fill = NA, colour = "grey15", linewidth = 0.25)
ctr <- data.frame(st_coordinates(st_point_on_surface(st_geometry(aoi))), lab = aoi$lab)
lab_fields <- geom_label(data = ctr, aes(X, Y, label = lab), size = (BASE - 1) / .pt, family = FONT,
                         fontface = "bold", linewidth = 0, fill = alpha("white", 0.75),
                         label.padding = unit(0.5, "mm"))
mapc <- coord_sf(expand = FALSE, datum = NA)
grp <- function(f) ifelse(f %in% c("F1", "F9", "F10"), "Main-crop maize",
                   ifelse(f == "F5", "Wheat", "Second-crop maize"))
GCOL <- c("Main-crop maize" = OKABE[[6]], "Second-crop maize" = OKABE[[2]], "Wheat" = OKABE[[5]])

# ---- Fig. 2: functional forms (schematic) ------------------------------------
N <- seq(0, 300, 1); Y <- pmin(6 + 0.04 * N - 1e-4 * N^2, 10); r <- 0.006
eonr <- (0.04 - r) / (2e-4); ye <- 6 + 0.04 * eonr - 1e-4 * eonr^2
pa <- ggplot(data.frame(N, Y), aes(N, Y)) + geom_line(linewidth = 0.6) +
  geom_abline(intercept = ye - r * eonr, slope = r, linetype = "dashed", colour = "grey45", linewidth = 0.4) +
  geom_vline(xintercept = eonr, linetype = "dotted", linewidth = 0.4) +
  annotate("text", x = eonr + 6, y = 6.6, label = "EONR", hjust = 0, size = BASE / .pt, family = FONT) +
  labs(x = expression("N rate (kg N ha"^-1*")"), y = expression("Yield (t ha"^-1*")")) + theme_sat()
W <- seq(1, 20, 0.1); Nc <- 3.40 * W^-0.37
obs <- data.frame(W = c(3, 6, 9, 12, 15, 4.5, 8, 13), Nobs = c(2.6, 2.2, 1.85, 1.7, 1.6, 1.9, 1.5, 1.25))
obs$state <- ifelse(obs$Nobs > 3.40 * obs$W^-0.37, "NNI > 1", "NNI < 1")
pb <- ggplot() + geom_line(data = data.frame(W, Nc), aes(W, Nc), linewidth = 0.6) +
  geom_point(data = obs, aes(W, Nobs, shape = state, colour = state), size = 1.6) +
  scale_colour_manual(values = c("NNI > 1" = "#2166ac", "NNI < 1" = "#b2182b"), name = NULL) +
  scale_shape_manual(values = c("NNI > 1" = 16, "NNI < 1" = 17), name = NULL) +
  annotate("text", x = 16, y = 3.40 * 16^-0.37 + 0.18, label = "critical N", size = BASE / .pt, family = FONT) +
  labs(x = expression("Shoot biomass (t DM ha"^-1*")"), y = "Plant N (% DM)") +
  theme_sat() + theme(legend.position = c(0.75, 0.85))
SI <- seq(0.6, 1, 0.002); Nr <- pmin(200 * sqrt(pmax(1 - SI, 0) / 0.3), 200)
pc <- ggplot(data.frame(SI, Nr), aes(SI, Nr)) + geom_line(linewidth = 0.6) +
  geom_hline(yintercept = 200, linetype = "dotted", linewidth = 0.4) +
  annotate("text", x = 0.61, y = 205, label = "regulatory ceiling", hjust = 0, vjust = 0, size = BASE / .pt, family = FONT) +
  scale_y_continuous(limits = c(0, 225)) +
  labs(x = "Sufficiency index (crop / N-rich reference)", y = expression("In-season N rate (kg N ha"^-1*")")) + theme_sat()
save_fig(add_tags(pa + pb + pc), "fig2_functional_forms", "double", 62)

# ---- Fig. 3: farm-scale canopy trajectories -----------------------------------
ts <- read.csv(file.path(DAT, "timeseries_fields.csv")); ts$date <- as.Date(ts$date); ts$group <- grp(ts$field)
long <- rbind(data.frame(ts[, c("date", "group")], var = "LAI", v = ts$LAI),
              data.frame(ts[, c("date", "group")], var = "CNC", v = ts$CNC))
agg <- do.call(rbind, lapply(split(long, list(long$date, long$group, long$var), drop = TRUE), function(d)
  data.frame(date = d$date[1], group = d$group[1], var = d$var[1], m = mean(d$v), lo = min(d$v), hi = max(d$v))))
agg$var <- factor(agg$var, levels = c("LAI", "CNC"),
                  labels = c("Leaf~area~index~(m^2~m^-2)", "Canopy~N~content~(g~N~m^-2)"))
p3 <- ggplot(agg, aes(date, m, colour = group, fill = group)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.18, colour = NA) +
  geom_line(linewidth = 0.5) + geom_point(size = 0.7) +
  facet_wrap(~var, ncol = 1, scales = "free_y", labeller = label_parsed, strip.position = "left") +
  scale_colour_manual(values = GCOL, name = NULL) + scale_fill_manual(values = GCOL, name = NULL) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b\n%Y") + labs(x = NULL, y = NULL) +
  theme_sat() + theme(legend.position = "top", strip.placement = "outside",
                      strip.text = element_text(face = "plain"))
save_fig(p3, "fig3_biophysical_timeseries", "double", 100)

# ---- Fig. 4: NNI across the farm ------------------------------------------------
pk <- read.csv(file.path(DAT, "peak_scenes.csv"))
grid10 <- rast(file.path(OUT, "N_mean_10m.tif"))         # common 10 m grid of the soil maps
nni <- Reduce(cover, lapply(aoi$field_id, function(id) {
  v <- vect(aoi[aoi$field_id == id, ])
  mask(resample(rast(file.path(OUT, sprintf("nni_%d.tif", id))), grid10, method = "near"), v, touches = FALSE)
})); nni <- trim(nni); names(nni) <- "NNI"
ctr$date <- format(as.Date(as.character(pk$date[match(ctr$lab, pk$field)]), "%Y%m%d"), "%d %b")
p4 <- ggplot() + geom_spatraster(data = nni) + fields +
  geom_label(data = ctr, aes(X, Y, label = paste0(lab, "\n", date)), size = (BASE - 1) / .pt, family = FONT,
             linewidth = 0, fill = alpha("white", 0.75), label.padding = unit(0.6, "mm"), lineheight = 0.9) +
  fill_NNI(breaks = c(0.6, 0.8, 0.9, 1, 1.1, 1.2, 1.4)) + map_furniture(bb) + mapc + theme_map() + cbar()
save_fig(p4, "fig4_nni_farm", "onehalf", 120)

# ---- Fig. 5: five prescription strategies -------------------------------------
S <- st_read(file.path(OUT, "strategies.geojson"), quiet = TRUE)
lv <- c("Uniform", "Calibration (inverse)", "Calibration (direct)", "Quantile classes", "NNI zones")
S$strategy <- factor(S$strategy, levels = lv)
lims <- range(S$dose)                                   # one colour scale for the five maps
panel <- function(s, furn = FALSE) ggplot(S[S$strategy == s, ]) + geom_sf(aes(fill = dose), colour = NA) + fields +
  fill_N(name = expression("N dose (kg N ha"^-1*")"), limits = lims) + (if (furn) map_furniture(bb) else NULL) +
  mapc + labs(title = s) + theme_map() + cbar()
S$rel <- 100 * S$dose / S$target
S$area <- as.numeric(st_area(S))
pd <- ggplot(S, aes(rel, factor(strategy, levels = rev(lv)), weight = area)) +
  geom_vline(xintercept = 100, linetype = "dotted", linewidth = 0.4) +
  geom_boxplot(width = 0.55, outlier.size = 0.4, linewidth = 0.3, fill = "grey92") +
  labs(x = "Dose (% of the field target)", y = NULL) + theme_sat()
save_fig(add_tags(wrap_plots(c(list(panel(lv[1], TRUE)), lapply(lv[-1], panel), list(pd)), ncol = 3,
                             guides = "collect") & theme(legend.position = "bottom")),
         "fig5_strategies", "double", 140)

# ---- Fig. 6: farm-scale application ----------------------------------------------
va <- vect(aoi)                                          # clip rasters to the field boundaries
Nm <- trim(mask(rast(file.path(OUT, "N_mean_10m.tif")), va, touches = FALSE)); names(Nm) <- "N"
Ns <- trim(mask(disagg(rast(file.path(OUT, "N_sd.tif")), 2), va, touches = FALSE));       names(Ns) <- "SD"
strips <- st_read(file.path(OUT, "farm_strips.geojson"), quiet = TRUE)
limN <- range(c(values(Nm, na.rm = TRUE), strips$dose))  # (a) and (c) share the dose scale
pA <- ggplot() + geom_spatraster(data = Nm) + fields + lab_fields + fill_N(limits = limN) + map_furniture(bb) + mapc + theme_map() + cbar()
pB <- ggplot() + geom_spatraster(data = Ns) + fields + fill_SD() + mapc + theme_map() + cbar()
pC <- ggplot() + geom_sf(data = strips, aes(fill = dose), colour = "grey40", linewidth = 0.05) + fields +
  fill_N(name = expression("Strip dose (kg N ha"^-1*")"), limits = limN) + mapc + theme_map() + cbar()
save_fig(add_tags(pA + pB + pC), "fig6_farm_multifield", "double", 88)

# ---- Fig. 7: sources and scaling of the soil-driven uncertainty --------------------
vd <- read.csv(file.path(DAT, "variance_decomposition.csv"))
sh <- do.call(rbind, lapply(split(vd, vd$crop_group), function(d)
  data.frame(crop = d$crop_group[1], texture = weighted.mean(d$share_texture, d$area_ha))))
lg <- rbind(data.frame(crop = sh$crop, source = "Soil texture", share = sh$texture),
            data.frame(crop = sh$crop, source = "Carbon-nitrogen", share = 100 - sh$texture))
lg$source <- factor(lg$source, levels = c("Carbon-nitrogen", "Soil texture"))
lg$crop <- factor(lg$crop, labels = c("Maize", "Wheat"))
p7a <- ggplot(lg, aes(crop, share, fill = source)) + geom_col(width = 0.6, colour = "grey20", linewidth = 0.2) +
  geom_text(data = transform(lg, y = ifelse(source == "Soil texture", share / 2, 100 + 4)),
            aes(y = y, label = sprintf("%.0f%%", share), colour = source),
            size = (BASE - 1) / .pt, family = FONT, show.legend = FALSE) +   # small share above the bar
  scale_colour_manual(values = c("Soil texture" = "white", "Carbon-nitrogen" = "black")) +
  scale_fill_manual(values = c("Soil texture" = OKABE[[5]], "Carbon-nitrogen" = "grey80"), name = NULL) +
  labs(x = NULL, y = "Share of the dose variance (%)") + theme_sat() + theme(legend.position = "top")
cv <- read.csv(file.path(DAT, "corr_length_curve.csv")); px <- read.csv(file.path(DAT, "uncert_pixel_summary.csv"))
ck <- read.csv(file.path(DAT, "corr_length_checks.csv")); ck$L_plot <- ifelse(is.na(ck$L_m), min(cv$L_m), ck$L_m)
L_MAX <- 150                                             # bound from the residual variogram (07)
p7b <- ggplot(cv, aes(L_m, sd_pct)) +
  annotate("rect", xmin = min(cv$L_m), xmax = L_MAX, ymin = -Inf, ymax = Inf, fill = "grey90") +
  annotate("text", x = sqrt(min(cv$L_m) * L_MAX), y = 1.7, label = "compatible with
map residuals",
           size = (BASE - 1) / .pt, family = FONT, lineheight = 0.9) +
  geom_hline(yintercept = px$sd_pct, linetype = "dotted", linewidth = 0.4) +
  annotate("text", x = min(cv$L_m), y = px$sd_pct, vjust = -0.6, hjust = 0, size = (BASE - 1) / .pt,
           family = FONT, label = sprintf("per-pixel uncertainty %.1f%%", px$sd_pct)) +
  geom_line(linewidth = 0.5, colour = OKABE[[5]]) + geom_point(size = 1.1, colour = OKABE[[5]]) +
  geom_point(data = ck, aes(L_plot, sd_direct_pct), shape = 4, size = 1.8, stroke = 0.7) +
  scale_x_log10(breaks = c(20, 50, 100, 200, 500, 1000)) + expand_limits(y = c(0, px$sd_pct * 1.12)) +
  labs(x = "Soil-error correlation length L (m)", y = "SD of the farm N total (%)") + theme_sat()
save_fig(add_tags(p7a + p7b + plot_layout(widths = c(0.8, 1.6))), "fig7_soil_uncertainty", "double", 68)

# ---- Supplementary S1: machine geometries --------------------------------------------
cnt <- read.csv(file.path(DAT, "grid_counts.csv"))
G <- lapply(cnt$width, function(w) st_read(file.path(OUT, sprintf("grids_%d.geojson", w)), quiet = TRUE))
limG <- range(unlist(lapply(G, `[[`, "dose")))            # one colour scale, one legend
gp <- lapply(seq_len(nrow(cnt)), function(k) { w <- cnt$width[k]
  ggplot(G[[k]]) + geom_sf(aes(fill = dose), colour = NA) + fields + fill_N(limits = limG) +
    (if (k == 1) map_furniture(bb) else NULL) + mapc + theme_map() + cbar() +
    labs(title = sprintf("%d m × %d m, %d cells", w, w, cnt$cells[k])) })
save_fig(add_tags(wrap_plots(gp, ncol = 2, guides = "collect") & theme(legend.position = "bottom")),
         "figS1_machine_geometries", "double", 160)

# ---- Supplementary S2: cell-size fidelity --------------------------------------------------
cf <- read.csv(file.path(DAT, "cellsize_fidelity.csv")); cf$r2 <- 100 * cf$r2
pS2 <- ggplot(cf, aes(cell_m, r2, colour = strategy, shape = strategy)) + geom_line(linewidth = 0.5) +
  geom_point(size = 1.3) +
  scale_colour_manual(values = unname(OKABE[c(5, 7, 2)]), name = NULL) + scale_shape_manual(values = c(16, 17, 15), name = NULL) +
  scale_x_continuous(breaks = sort(unique(cf$cell_m))) + scale_y_continuous(limits = c(0, 100)) +
  labs(x = "Square cell size (m)", y = expression(R^2*" with the 10 m prescription (%)")) +
  theme_sat() + theme(legend.position = c(0.7, 0.8))
save_fig(pS2, "figS2_cellsize_fidelity", "single", 70)
cat("figures written to paper/sat/figures\n")
