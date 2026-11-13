# Inputs per field for the Piacenza plain application (Section 3.4 of the SoftwareX article).
# Fields: satellite-delineated map fields with an estimated crop class per year (2019-2025: 15
# classes; 2026: provisional 9-class estimate). Soil: Emilia-Romagna soil maps 0-30 cm (100 m):
# clay, sand, organic carbon, total N, Olsen P, exchangeable K. Weather: ERA5 daily rainfall
# (Open-Meteo), summed October-January and February of each crop year. Yields: ISTAT, Piacenza.
# Run from the package root:  Rscript paper/sat/../softwarex/piacenza/a01_inputs.R
# Environment: KWASI_DATA (field and crop layers), RER_SOIL (regional soil rasters).
# Output: paper/softwarex/piacenza/data/fields.rds (no field identifiers leave this folder)
suppressMessages({ library(terra); library(sf) })
HERE <- "paper/softwarex/piacenza"
KW   <- Sys.getenv("KWASI_DATA", "C:/Users/michele.croci/Desktop/kwasi-data")
SOIL <- Sys.getenv("RER_SOIL", file.path("C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
                   "rds/research/8. db-and-layer-soil-meteo-limits/soil-properties/rer"))
GPKG <- file.path(KW, "uscita/pianura_piacenza.gpkg")

# ---- fields and crops -------------------------------------------------------------
f15 <- st_read(file.path(KW, "uscita/consegna/crop_maps_shapefiles/crops_15classes.shp"), quiet = TRUE)
f26 <- st_read(GPKG, layer = "campi_pezzi_2026_s2", quiet = TRUE)[, c("ha", "c9_2026")]
f26 <- st_transform(f26, st_crs(f15))
pt <- suppressWarnings(st_point_on_surface(st_geometry(f15)))   # the two layers number fields differently
hit <- vapply(st_intersects(pt, f26), function(i) if (length(i)) i[1] else NA_integer_, 1L)
f15$c2026 <- f26$c9_2026[hit]
cat("fields", nrow(f15), "| ha", round(sum(f15$ha)), "| with a 2026 estimate", sum(!is.na(f15$c2026)), "\n")

# ---- municipality (for aggregated output only) -------------------------------------
com <- st_transform(st_read(GPKG, layer = "comuni", quiet = TRUE), st_crs(f15))
ctr <- pt
f15$comune <- com[[grep("COMUNE|comune|nome", names(com), value = TRUE)[1]]][
  vapply(st_intersects(ctr, com), function(i) if (length(i)) i[1] else NA_integer_, 1L)]

# ---- soil: zonal means on the regional 100 m grid ----------------------------------
rs <- c(rast(file.path(SOIL, "ARGILLA_0_30.tif")), rast(file.path(SOIL, "SABBIA_0_30.tif")),
        rast(file.path(SOIL, "CORG_0_30.tif")), rast(file.path(SOIL, "npk_0_30/Azoto_N_totale/N_0_30.tif")),
        rast(file.path(SOIL, "npk_0_30/Fosforo_P_assimilabile/P_0_30.tif")),
        rast(file.path(SOIL, "npk_0_30/Potassio_K_scambiabile/K_0_30.tif")))
names(rs) <- c("clay", "sand", "corg", "ntot", "olsen_p", "k_exch")
v <- vect(st_transform(f15, crs(rs)))
rs <- crop(rs, ext(v) + 500)
rs <- classify(rs, cbind(-Inf, 0, NA))                    # the clay map carries unflagged negative fill values
sm <- terra::extract(rs, v, fun = mean, na.rm = TRUE, touches = TRUE, ID = FALSE)
f15 <- cbind(f15, sm)

# ---- ERA5 rainfall per crop year -----------------------------------------------------
p <- read.csv(file.path(HERE, "data/era5_daily_precip.csv"))
p$date <- as.Date(p$date); mo <- as.integer(format(p$date, "%m")); yr <- as.integer(format(p$date, "%Y"))
p$crop_year <- ifelse(mo >= 10, yr + 1L, yr)
p$period <- ifelse(mo >= 10 | mo == 1, "ondj", ifelse(mo == 2, "feb", NA))
rain <- aggregate(precip_mm ~ lat + lon + crop_year + period, p[!is.na(p$period), ], sum)
cells <- unique(rain[, c("lat", "lon")])
cxy <- st_transform(st_as_sf(cells, coords = c("lon", "lat"), crs = 4326), st_crs(f15))
f15$cell <- st_nearest_feature(ctr, cxy)
cells$cell <- seq_len(nrow(cells))
rain <- merge(rain, cells)
write.csv(reshape(rain[, c("cell", "crop_year", "period", "precip_mm")], idvar = c("cell", "crop_year"),
                  timevar = "period", direction = "wide"), file.path(HERE, "data/era5_seasonal.csv"), row.names = FALSE)

saveRDS(st_drop_geometry(f15), file.path(HERE, "data/fields.rds"))
cat("soil coverage (share of fields with all six properties):",
    round(mean(complete.cases(sm)), 3), "\n")
print(summary(sm))
