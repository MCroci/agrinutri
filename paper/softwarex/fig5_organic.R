# Fig. 5: organic + mineral plan of plot P01 (maize 2024): dairy slurry at three distribution efficiencies,
# urea up to the balance dose. Run from the package root:  Rscript paper/softwarex/fig5_organic.R
suppressMessages({ library(sf); library(ggplot2); library(patchwork) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
farm <- st_read(system.file("extdata/piacenza_farm.geojson", package = "agrinutri"), quiet = TRUE)
p1 <- farm[farm$plot == "P01", ]
Nstar <- farm_balance(farm)$N_target[farm$plot == "P01"]
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
save_fig(pa, "fig5_organic", "single", 80)
print(pl)
