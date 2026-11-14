# Example data from the Piacenza plain used in the vignettes and in the SoftwareX article
# (Sections 3.2-3.5). Run from the package root after paper/softwarex/fig2_farm.R,
# fig3_p01_years.R and fig4_data.R. Writes to inst/extdata/:
#   piacenza_farm.geojson          four satellite-delineated fields (P01-P04), crop 2019-2026,
#                                  field-mean soil (Olsen P, exchangeable K as elements, for p_balance/k_balance) and the farm_balance() inputs of 2024
#   piacenza_p01_rotation.csv      yearly balance inputs of plot P01, 2019-2026
#   sentinel-2/S2_piacenza_P01_20240813.tif   Sentinel-2 L2A over P01 (reflectance x 10000)
#   rer_soil_piacenza.tif          regional soil maps 0-30 cm, 100 m, around the farm
# Original field identifiers are dropped.
suppressMessages({ library(sf); library(terra) })
D <- "paper/softwarex/data"; X <- "inst/extdata"
SOIL <- Sys.getenv("RER_SOIL", file.path("C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
                   "rds/research/8. db-and-layer-soil-meteo-limits/soil-properties/rer"))

EN <- c("mais" = "Maize", "cereali vernini" = "Winter cereals", "prato e medica" = "Alfalfa",
        "pomodoro" = "Processing tomato", "altre estive" = "Other summer crops")   # 2026 class names
farm <- readRDS(file.path(D, "rs_farm_2024.rds"))
yc <- paste0("c", 2019:2026)
for (y in yc) farm[[y]] <- ifelse(farm[[y]] %in% names(EN), EN[farm[[y]]], farm[[y]])
farm$olsen_value <- farm$olsen_p; farm$olsen_unit <- "P"; farm$k_value <- farm$k_exch; farm$k_unit <- "K"
keep <- c("plot", "area_ha", yc, "clay", "sand", "olsen_value", "olsen_unit", "k_value", "k_unit",   # Ntot, SOM below (GeoJSON names are case-insensitive)
          "crop", "ccp", "expected_yield_tons_ha", "prev_crop", "Ntot", "SOM", "CN", "oxygen_availability",
          "winter_rain", "start_spring_rain", "source", "fertorg_frequency", "location", "forg_quantity")
farm <- farm[, keep]
num <- vapply(st_drop_geometry(farm), is.numeric, TRUE)
for (k in names(num)[num]) farm[[k]] <- round(farm[[k]], 3)
farm <- st_transform(farm, 32632)
st_write(farm, file.path(X, "piacenza_farm.geojson"), delete_dsn = TRUE, quiet = TRUE,
         layer_options = "COORDINATE_PRECISION=1")

yr <- read.csv(file.path(D, "p01_years.csv"), stringsAsFactors = FALSE)
yr$class <- ifelse(yr$class %in% names(EN), EN[yr$class], yr$class)
rot <- data.frame(year = yr$year, crop_class = yr$class, crop = yr$crop, ccp = yr$ccp,
                  prev_crop = yr$prev_crop, expected_yield_tons_ha = round(yr$yield, 2),
                  winter_rain = yr$rain, start_spring_rain = yr$spring_rain)
write.csv(rot, file.path(X, "piacenza_p01_rotation.csv"), row.names = FALSE)

file.copy(file.path(D, "rs_s2_20240813.tif"), file.path(X, "sentinel-2/S2_piacenza_P01_20240813.tif"), overwrite = TRUE)

rs <- c(rast(file.path(SOIL, "ARGILLA_0_30.tif")), rast(file.path(SOIL, "SABBIA_0_30.tif")),
        rast(file.path(SOIL, "CORG_0_30.tif")), rast(file.path(SOIL, "npk_0_30/Azoto_N_totale/N_0_30.tif")),
        rast(file.path(SOIL, "npk_0_30/Fosforo_P_assimilabile/P_0_30.tif")),
        rast(file.path(SOIL, "npk_0_30/Potassio_K_scambiabile/K_0_30.tif")))
names(rs) <- c("clay", "sand", "corg", "ntot", "olsen_p", "k_exch")
bb <- ext(vect(st_transform(farm, crs(rs)))) + 1500          # the farm and 1.5 km around it
rs <- classify(crop(rs, bb, snap = "out"), cbind(-Inf, 0, NA))   # clay map: unflagged negative fill values
writeRaster(round(rs, 2), file.path(X, "rer_soil_piacenza.tif"), overwrite = TRUE, datatype = "FLT4S",
            gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"))

stopifnot(nrow(farm) == 4, nrow(rot) == 8, nlyr(rast(file.path(X, "rer_soil_piacenza.tif"))) == 6)
print(file.size(file.path(X, c("piacenza_farm.geojson", "piacenza_p01_rotation.csv",
                               "sentinel-2/S2_piacenza_P01_20240813.tif", "rer_soil_piacenza.tif"))))
