# Fig. 9: re-parameterising the balance with agrinutri_tables(): the rotation of plot P01 with the bundled
# and with an edited uptake table. Run from the package root:  Rscript paper/softwarex/fig9_tables.R
suppressMessages({ library(sf); library(ggplot2); library(patchwork) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
farm <- st_read(system.file("extdata/piacenza_farm.geojson", package = "agrinutri"), quiet = TRUE)
p1 <- farm[farm$plot == "P01", ]
Nstar <- farm_balance(farm)$N_target[farm$plot == "P01"]
rot <- read.csv(system.file("extdata/piacenza_p01_rotation.csv", package = "agrinutri"))
dose <- function() vapply(seq_len(nrow(rot)), function(i) { r <- rot[i, ]
  calculate_N_fertilization(N_balance(r$expected_yield_tons_ha, r$crop, r$ccp, sand = p1$sand, clay = p1$clay,
    Ntot = p1$Ntot, SOM = p1$SOM, CN = p1$CN, winter_rain = r$winter_rain, start_spring_rain = r$start_spring_rain,
    prev_crop = r$prev_crop, source = "None", location = p1$location, forg_quantity = 0)) }, numeric(1))
d0 <- dose()
my <- uptake_table; my$N <- my$N * 1.1                                 # illustrative edit: unit N uptake +10 percent
old <- agrinutri_tables(uptake_table = my); d1 <- dose(); agrinutri_tables()
dx <- data.frame(year = rot$year, crop = rot$crop_class, default = d0, edited = d1)
dx$lab <- factor(paste0(dx$year, "\n", gsub(" ", "\n", dx$crop)), levels = paste0(dx$year, "\n", gsub(" ", "\n", dx$crop)))
code <- c("my <- uptake_table", "my$N <- my$N * 1.1", "agrinutri_tables(uptake_table = my)",
          "N_balance(...)       # every call uses it", "agrinutri_tables()   # bundled tables again")
pc <- ggplot() + annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 1, fill = "grey97", colour = "grey60", linewidth = 0.3) +
  annotate("text", x = 0.04, y = seq(0.86, by = -0.18, length.out = length(code)), label = code, hjust = 0,
           family = "mono", size = (BASE - 1.5) / .pt) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) + theme_void()
pd <- ggplot(dx, aes(lab)) +
  geom_segment(aes(y = default, yend = edited, xend = lab), colour = "grey55", linewidth = 0.7) +
  geom_point(aes(y = default, colour = "bundled table"), size = 2.2) +
  geom_point(aes(y = edited, colour = "edited table (+10% N uptake)"), size = 2.2) +
  scale_colour_manual(values = c("bundled table" = OKABE[[5]], "edited table (+10% N uptake)" = OKABE[[6]]), name = NULL) +
  labs(x = NULL, y = expression("Balance dose (kg N ha"^-1*")")) + theme_sat() +
  theme(legend.position = "top", axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9))
save_fig(add_tags(pc + pd + plot_layout(widths = c(1.15, 1.45))), "fig9_tables", "double", 62)
print(dx[, 1:4])
