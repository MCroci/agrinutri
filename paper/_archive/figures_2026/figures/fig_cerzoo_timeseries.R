# Reproduce the CERZOO Field 3 seasonal time series (Figures 2 and 3) with
# English labels, from the Sentinel-2 archive of the companion lab.
#
# For every S2 scene in 2024-2025: crop/mask to Field 3, retrieve biophysical
# variables by GPR (estimate_biophysical), take the field mean +/- SD, and
# compute the NNI with the maize critical-N curve (Lemaire-Gastal, W >= 1.0
# t DM/ha filter, identical to lab exercise 06). The per-scene table is cached
# to cerzoo_timeseries_data.csv so the plots can be regenerated without the
# heavy GPR loop.
#
# Output: paper/figures/cerzoo_biophysical_ts.png, cerzoo_nni_ts.png

suppressWarnings(suppressMessages({
  library(terra); library(sf); library(ggplot2); pkgload::load_all(".", quiet = TRUE)
}))
# English month names on the date axis (R session locale may be Italian).
suppressWarnings(try(Sys.setlocale("LC_TIME", "C"), silent = TRUE))

lab <- "C:/Users/michele.croci/OneDrive - Universita Cattolica del Sacro Cuore/rds/teaching/2027/Fondamenti di agricoltura di precisione/lab-agricoltura-di-precisione"
if (!dir.exists(lab))
  lab <- normalizePath(file.path(
    "C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
    "rds/teaching/2027/Fondamenti di agricoltura di precisione",
    "lab-agricoltura-di-precisione"), mustWork = TRUE)

CACHE <- "paper/figures/cerzoo_timeseries_data.csv"
field3 <- sf::st_read(system.file("extdata/cerzoo_field.geojson", package = "NFert"),
                      quiet = TRUE)
field3 <- field3[as.character(field3$id) == "3", ]

biop_vars <- c("LAI", "Cm", "CNC_Cprot", "FVC")
p <- crop_params_NNI("maize")
W_MIN <- 1.0

vals <- function(x) if (inherits(x, "SpatRaster")) terra::values(x, mat = FALSE) else
  as.numeric(terra::values(terra::rast(x), mat = FALSE))

if (file.exists(CACHE)) {
  ts <- utils::read.csv(CACHE); ts$date <- as.Date(ts$date)
} else {
  scenes <- list.files(file.path(lab, "input/sentinel-2"),
                       pattern = "(?i)\\.tif$", full.names = TRUE)
  dts <- as.Date(regmatches(basename(scenes), regexpr("20\\d{6}", basename(scenes))), "%Y%m%d")
  keep <- !is.na(dts) & dts >= as.Date("2024-01-01") & dts <= as.Date("2025-12-31")
  scenes <- scenes[keep]; dts <- dts[keep]; o <- order(dts); scenes <- scenes[o]; dts <- dts[o]
  cat("scenes 2024-2025:", length(scenes), "\n")

  f3v <- terra::vect(field3)
  rows <- list()
  for (i in seq_along(scenes)) {
    d <- dts[i]
    r <- tryCatch(terra::rast(scenes[i]), error = function(e) NULL)
    if (is.null(r) || terra::nlyr(r) < 10) next
    r <- r[[1:10]]; names(r) <- c("B02","B03","B04","B05","B06","B07","B08","B8A","B11","B12")
    fv <- terra::project(f3v, terra::crs(r))
    sub <- tryCatch(terra::mask(terra::crop(r, fv), fv), error = function(e) NULL)
    if (is.null(sub)) next
    tf <- tempfile(fileext = ".tif"); terra::writeRaster(sub, tf, overwrite = TRUE)
    od <- tempfile(); dir.create(od)
    maps <- tryCatch(estimate_biophysical(raster_path = tf, output_dir = od,
                                          variables = biop_vars, scale = 10000,
                                          apply_offset = FALSE, nodata_in = 0, block_rows = 64),
                     error = function(e) NULL)
    if (is.null(maps)) { cat(format(d), "biop FAIL\n"); next }
    # biophysical field mean +/- sd
    bs <- lapply(biop_vars, function(v) { x <- vals(maps[[v]]); c(mean(x, na.rm = TRUE), stats::sd(x, na.rm = TRUE)) })
    # NNI (Lemaire-Gastal, identical to lab exercise 06)
    lai <- vals(maps$LAI); cm <- vals(maps$Cm); cnc <- vals(maps$CNC_Cprot)
    ok <- is.finite(lai) & is.finite(cm) & is.finite(cnc) & lai > 0 & cm > 0
    nni_m <- NA_real_; nni_s <- NA_real_
    if (any(ok)) {
      W_total <- pmax((lai[ok] * cm[ok] * 1e4) / p$alpha_leaf, 1e-6)
      W_tha   <- pmax(W_total * 0.01, 1e-6)
      nni     <- (100 * cnc[ok] / W_total) / (p$a * W_tha^(-p$b))
      tr <- W_tha >= W_MIN & is.finite(nni)
      if (any(tr)) { nni_m <- mean(nni[tr]); nni_s <- stats::sd(nni[tr]) }
    }
    rows[[length(rows) + 1]] <- data.frame(
      date = d, var = c(biop_vars, "NNI"),
      mean = c(vapply(bs, `[`, numeric(1), 1), nni_m),
      sd   = c(vapply(bs, `[`, numeric(1), 2), nni_s))
    cat(sprintf("[%d/%d] %s ok\n", i, length(scenes), format(d)))
  }
  ts <- do.call(rbind, rows)
  utils::write.csv(ts, CACHE, row.names = FALSE)
}

# ---- PLOT 1: biophysical variables (English) --------------------------------
unit_labels <- c(
  LAI       = "'LAI (Leaf Area Index)'~~~group('[',m^2~m^{-2},']')",
  Cm        = "'Cm (Leaf dry matter content)'~~~group('[',g~cm^{-2},']')",
  CNC_Cprot = "'CNC (Canopy N content)'~~~group('[',g~N~m^{-2},']')",
  FVC       = "'FVC (Fractional Vegetation Cover)'~~~group('[','fraction (0-1)',']')")
bl <- subset(ts, var %in% biop_vars); bl$var <- factor(bl$var, levels = names(unit_labels))
cols <- c(LAI = "#2E7D32", Cm = "#8E24AA", CNC_Cprot = "#C0392B", FVC = "#1F4E79")

p1 <- ggplot(bl, aes(date, mean, colour = var, fill = var)) +
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd), alpha = 0.20, colour = NA) +
  geom_line(linewidth = 0.8) + geom_point(size = 1.4, na.rm = TRUE) +
  facet_wrap(~ var, scales = "free_y", ncol = 2,
             labeller = labeller(var = as_labeller(unit_labels, label_parsed))) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_fill_manual(values = cols, guide = "none") +
  scale_x_date(date_labels = "%b %Y") +
  labs(x = "Acquisition date", y = "Field mean (with +/-1 SD band)") +
  theme_bw(base_size = 12) +
  theme(strip.text = element_text(face = "bold", size = 10),
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 35, hjust = 1, size = 9))
ggsave("paper/figures/cerzoo_biophysical_ts.png", p1, width = 10, height = 6, dpi = 200, bg = "white")

# ---- PLOT 2: NNI with agronomic zones (English) -----------------------------
nl <- subset(ts, var == "NNI")
bands <- data.frame(ymin = c(-Inf, 0.90, 1.10), ymax = c(0.90, 1.10, Inf),
                    status = factor(c("Deficient (<0.90)", "Optimal (0.90-1.10)", "Excess (>1.10)"),
                                    levels = c("Deficient (<0.90)", "Optimal (0.90-1.10)", "Excess (>1.10)")))
p2 <- ggplot() +
  geom_rect(data = bands, aes(xmin = min(nl$date) - 5, xmax = max(nl$date) + 5,
                              ymin = ymin, ymax = ymax, fill = status), alpha = 0.55) +
  scale_fill_manual(values = c("Deficient (<0.90)" = "#FCE7E7", "Optimal (0.90-1.10)" = "#E8F5E9",
                               "Excess (>1.10)" = "#FFF8E1"), name = "NNI zone") +
  geom_hline(yintercept = c(0.90, 1.00, 1.10), linetype = c("dashed","solid","dashed"),
             colour = c("#C0392B","#2E8B57","#C0392B"), linewidth = 0.4) +
  geom_ribbon(data = nl, aes(date, ymin = mean - sd, ymax = mean + sd), fill = "#D97706", alpha = 0.20) +
  geom_line(data = nl, aes(date, mean), colour = "#D97706", linewidth = 0.8) +
  geom_point(data = nl, aes(date, mean), colour = "#D97706", size = 1.6, na.rm = TRUE) +
  scale_x_date(date_labels = "%b %Y") + coord_cartesian(ylim = c(0, 2)) +
  labs(x = "Acquisition date", y = "NNI (dimensionless)") +
  theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 35, hjust = 1, size = 9),
        legend.position = "bottom")
ggsave("paper/figures/cerzoo_nni_ts.png", p2, width = 10, height = 4.2, dpi = 200, bg = "white")
cat("DONE timeseries\n")
