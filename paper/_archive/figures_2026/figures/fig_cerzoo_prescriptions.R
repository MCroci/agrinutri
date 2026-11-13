# Re-plot the CERZOO Field 3 variable-rate prescription strategies (Figure 4)
# with English labels, from the precomputed strip grids of lab exercise 07.
#
#   Data source : <lab>/output/07_prescrizione_VRT/grids.rds  (built by 07_prescrizione_VRT.R)
#   Output      : paper/figures/cerzoo_prescription_strategies.png
#
# The doses are already computed (one sf per strategy, column `dose`); this
# script only re-labels and re-renders, so no recomputation is needed.

suppressWarnings(suppressMessages({ library(sf); library(ggplot2) }))

lab <- "C:/Users/michele.croci/OneDrive - Universita Cattolica del Sacro Cuore/rds/teaching/2027/Fondamenti di agricoltura di precisione/lab-agricoltura-di-precisione"
if (!dir.exists(lab))
  lab <- normalizePath(file.path(
    "C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
    "rds/teaching/2027/Fondamenti di agricoltura di precisione",
    "lab-agricoltura-di-precisione"), mustWork = TRUE)

g <- readRDS(file.path(lab, "output/07_prescrizione_VRT/grids.rds"))

# English strategy labels, in the same order as the comparison table.
labs_en <- c(
  uniforme                        = "Uniform",
  calibrazione_pendenza_negativa  = "Calibration (inverse): NDVI up, dose down",
  calibrazione_pendenza_positiva  = "Calibration (direct): NDVI up, dose up",
  classi                          = "Quantile classes (5)",
  nni                             = "NNI zones (3)"
)

mk <- function(key) {
  s <- sf::st_transform(g[[key]], 3857)
  s$dose <- as.numeric(s$dose)
  s$strategy <- labs_en[[key]]
  s[, c("strategy", "dose")]
}
all_rx <- do.call(rbind, lapply(names(labs_en), mk))
all_rx$strategy <- factor(all_rx$strategy, levels = unname(labs_en))

p <- ggplot(all_rx) +
  geom_sf(aes(fill = dose), colour = "grey40", linewidth = 0.15) +
  scale_fill_gradientn(colours = rev(hcl.colors(20, "RdYlGn")),
                       name = expression("N (kg ha"^{-1}*")")) +
  facet_wrap(~ strategy, ncol = 5) +
  theme_void(base_size = 13) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    strip.background = element_rect(fill = "white", colour = NA),
    strip.text       = element_text(face = "bold", colour = "grey10"),
    legend.position  = "bottom",
    legend.key.width = unit(2, "cm")
  )

out <- "paper/figures/cerzoo_prescription_strategies.png"
ggsave(out, p, width = 34, height = 8.5, dpi = 200, bg = "white")
cat("Wrote", out, "\n")
