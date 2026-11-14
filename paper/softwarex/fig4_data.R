# Data for Figs. 4-5: a satellite-delineated maize field of the Piacenza plain (Fields of The World
# boundary, data/rs_field.geojson) and the Sentinel-2 L2A scene of 13 August 2024, clipped to it.
# Run from paper/softwarex/:  Rscript fig4_data.R
# Environment: PRESTO_DEPLOY (folder of the Sentinel-2 archive).
suppressMessages(pkgload::load_all("../..", quiet = TRUE))
S2 <- file.path(Sys.getenv("PRESTO_DEPLOY", "C:/Users/michele.croci/Desktop/presto-deploy"),
                "data/rasters/downloads_sentinelhub_2019_2026/S2_20240813_B02_B03_B04_B05_B06_B07_B08_B8A_B11_B12_SCL_10m.tif")
field <- sf::st_read("data/rs_field.geojson", quiet = TRUE)
r <- terra::rast(S2)
fv <- terra::vect(sf::st_transform(field, terra::crs(r)))
x <- terra::crop(r, terra::ext(fv) + 30)
scl <- round(x[[11]] / 10000)
x <- terra::mask(x[[1:10]], scl >= 4 & scl <= 5, maskvalues = FALSE)   # SCL 4-5: vegetation, bare soil
names(x) <- c("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12")
s2 <- "data/rs_s2_20240813.tif"
terra::writeRaster(x, s2, overwrite = TRUE, NAflag = 0)

bio <- estimate_biophysical(s2, output_dir = tempdir(), variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot",
                           crop = "maize", fvc = bio$FVC)
Nstar <- read.csv("data/farm_2024.csv")$N_target[1]           # balance dose of plot P01 (Fig. 2)
rx <- build_strip_prescription(field, machine_width = 24, cell_length = 30,
                               variability = "nni", nni_raster = nni$NNI,
                               n_target = Nstar, min_dose = 0.8 * Nstar, max_dose = 1.2 * Nstar)
terra::writeRaster(nni$NNI, "data/rs_NNI_full.tif", overwrite = TRUE)
lai <- terra::mask(terra::crop(bio$LAI, fv), fv)
nn  <- terra::mask(terra::crop(nni$NNI, fv), fv)
terra::writeRaster(lai, "data/rs_LAI.tif", overwrite = TRUE)
terra::writeRaster(nn,  "data/rs_NNI.tif", overwrite = TRUE)
sf::st_write(sf::st_transform(rx, terra::crs(bio$LAI)), "data/rs_rx.geojson",
             delete_dsn = file.exists("data/rs_rx.geojson"), quiet = TRUE)
sf::st_write(sf::st_transform(field, terra::crs(bio$LAI)), "data/rs_field_utm.geojson",
             delete_dsn = file.exists("data/rs_field_utm.geojson"), quiet = TRUE)
v <- terra::values(nn, na.rm = TRUE)
cat("pixels", length(v), " NNI median", round(median(v), 2),
    " zones (<0.9, 0.9-1.1, >1.1):", sum(v < 0.9), sum(v >= 0.9 & v <= 1.1), sum(v > 1.1), "\n")
cat("LAI median", round(median(terra::values(lai, na.rm = TRUE)), 2), "\n")
cat("cells", nrow(rx), " dose range", range(rx$dose), " area-weighted mean",
    round(stats::weighted.mean(rx$dose, rx$area_ha), 1), " field ha", round(sum(rx$area_ha), 2), "\n")
print(table(rx$dose))
