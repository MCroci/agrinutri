# In-season within-field canopy nitrogen status: red-edge NDRE map for CERZOO Field 3
# (peak maize, 13 Aug 2024). Reliable via compute_vi; a proxy for the Nitrogen
# Nutrition Index while the operational NNI retrieval is calibration-checked.
suppressMessages({
  pkgload::load_all("C:/Users/michele.croci/Documents/GitHub/NFert", quiet = TRUE)
  library(terra); library(ggplot2); library(tidyterra); library(scales)
})
SP <- "C:/Users/MICHEL~1.CRO/AppData/Local/Temp/claude/C--Users-michele-croci-Documents-GitHub-NFert/b5b9999e-d385-4c3e-84cf-b776ad94bd7c/scratchpad"
scene <- rast(system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif", package = "NFert"))
ndre <- compute_vi(scene, "NDRE", scale_factor = 10000)
ndvi <- compute_vi(scene, "NDVI", scale_factor = 10000)
# mask to vegetated canopy (NDVI > 0.4) to focus on the crop
veg <- ndvi > 0.4
R <- mask(ndre, veg, maskvalues = FALSE); names(R) <- "NDRE"
R <- trim(R)
v <- values(R, na.rm = TRUE)
cat(sprintf("NDRE (veg pixels) n=%d mean %.3f range %.3f..%.3f CV %.1f%%\n",
            length(v), mean(v), min(v), max(v), 100 * sd(v) / mean(v)))

p <- ggplot() +
  geom_spatraster(data = R) +
  scale_fill_viridis_c(option = "viridis", na.value = "transparent", name = "NDRE",
                       limits = quantile(v, c(0.02, 0.98))) +
  coord_sf(expand = FALSE) +
  theme_minimal(base_size = 12) +
  theme(axis.title = element_blank(), axis.text = element_blank(), panel.grid = element_blank(),
        plot.title = element_text(face = "bold"), plot.subtitle = element_text(color = "grey30")) +
  labs(title = "Canopy N status (red-edge NDRE)",
       subtitle = "CERZOO Field 3, 13 Aug 2024. Within-field CV 14.8 percent")
ggsave(file.path(SP, "fig_canopy_ndre.png"), p, width = 6.4, height = 6.0, dpi = 200, bg = "white")
cat("saved fig_canopy_ndre.png\n")
