# Multi-field (farm-scale) figure: N recommendation + its uncertainty over the 8 CERZOO fields.
suppressMessages({library(terra); library(sf); library(ggplot2); library(tidyterra); library(patchwork)})
SP  <- "C:/Users/MICHEL~1.CRO/AppData/Local/Temp/claude/C--Users-michele-croci-Documents-GitHub-NFert/b5b9999e-d385-4c3e-84cf-b776ad94bd7c/scratchpad"
RAW <- "C:/Users/michele.croci/Desktop/presto-deploy/data/raw/cerzoo"
Nm <- trim(rast(file.path(SP,"mc_farm_out/N_mean_10m.tif"))); names(Nm) <- "N"
Ns <- trim(rast(file.path(SP,"mc_v2_out/N_sd.tif")));         names(Ns) <- "SD"
aoi <- st_transform(st_read(file.path(RAW,"aoi_multi_cerzoo_fields.geojson"), quiet=TRUE), 32632)
aoi$lab <- paste0("F", aoi$field_id)
ctr <- st_centroid(st_geometry(aoi))
labs <- data.frame(st_coordinates(ctr), lab = aoi$lab)

base_theme <- theme_void(base_size = 12) +
  theme(legend.position="bottom",
        legend.key.width=unit(1.5,"cm"), legend.key.height=unit(0.35,"cm"),
        legend.title=element_text(vjust=0.85),
        plot.title=element_text(face="bold", size=12, hjust=0.5),
        plot.margin=margin(2,2,2,2))
guide_h <- guides(fill=guide_colorbar(title.position="left"))

pA <- ggplot() +
  geom_spatraster(data=Nm) +
  geom_sf(data=aoi, fill=NA, color="grey15", linewidth=0.35) +
  geom_text(data=labs, aes(X,Y,label=lab), size=3, fontface="bold", color="grey95") +
  scale_fill_viridis_c(option="mako", direction=-1, na.value="transparent", name="N (kg/ha)  ") +
  coord_sf(expand=FALSE) + base_theme + guide_h +
  labs(title="a  Nitrogen recommendation")

pB <- ggplot() +
  geom_spatraster(data=Ns) +
  geom_sf(data=aoi, fill=NA, color="grey15", linewidth=0.35) +
  scale_fill_viridis_c(option="rocket", direction=-1, na.value="transparent", name="SD (kg/ha)  ") +
  coord_sf(expand=FALSE) + base_theme + guide_h +
  labs(title="b  Recommendation uncertainty")

strips <- st_transform(st_read(file.path(SP,"strips_out/cerzoo_farm_strips.geojson"), quiet=TRUE), 32632)
pC <- ggplot() +
  geom_sf(data=strips, aes(fill=dose), color="grey35", linewidth=0.08) +
  geom_sf(data=aoi, fill=NA, color="grey15", linewidth=0.35) +
  scale_fill_viridis_c(option="mako", direction=-1, na.value="transparent", name="dose (kg/ha)  ") +
  coord_sf(expand=FALSE) + base_theme + guide_h +
  labs(title="c  Strip prescription (24 m)")

fig <- pA + pB + pC + plot_layout(ncol=3) &
  theme(plot.margin=margin(2,2,2,2))
ggsave(file.path(SP,"fig_farm_multifield.png"), fig, width=13.5, height=5.6, dpi=200, bg="white")
cat("saved fig_farm_multifield.png\n")
cat(sprintf("N range %.0f..%.0f kg/ha | SD range %.1f..%.1f kg/ha\n",
    min(values(Nm),na.rm=T), max(values(Nm),na.rm=T), min(values(Ns),na.rm=T), max(values(Ns),na.rm=T)))
