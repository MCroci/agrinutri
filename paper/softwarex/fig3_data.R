# Data for Fig. 3 (bundled Sentinel-2 demo scene of CERZOO Field 3, 13 Aug 2024):
# run from paper/softwarex/:  Rscript fig3_data.R
suppressMessages(pkgload::load_all("../..", quiet = TRUE))
s2  <- system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif", package = "NFert")
bio <- estimate_biophysical(s2, output_dir = tempdir(),
                            variables = c("LAI", "Cm", "CNC_Cprot", "FVC"))
nni <- compute_NNI_from_S2(bio$LAI, bio$Cm, bio$CNC_Cprot, cnc_layer = "CNC_Cprot",
                           crop = "maize", fvc = bio$FVC)
farm  <- sf::st_read(system.file("extdata/cerzoo_field.geojson", package = "NFert"), quiet = TRUE)
field <- farm[farm$id == 3, ]
rx <- build_strip_prescription(field, machine_width = 24, cell_length = 30,
                               variability = "nni", nni_raster = nni$NNI,
                               n_target = 200, min_dose = 160, max_dose = 240)
fv <- terra::vect(sf::st_transform(field, terra::crs(bio$LAI)))
lai <- terra::mask(terra::crop(bio$LAI, fv), fv)
nn  <- terra::mask(terra::crop(nni$NNI, fv), fv)
terra::writeRaster(lai, "data/cerzoo_f3_LAI.tif", overwrite = TRUE)
terra::writeRaster(nn,  "data/cerzoo_f3_NNI.tif", overwrite = TRUE)
sf::st_write(sf::st_transform(rx, terra::crs(bio$LAI)), "data/cerzoo_f3_rx.geojson",
             delete_dsn = file.exists("data/cerzoo_f3_rx.geojson"), quiet = TRUE)
sf::st_write(sf::st_transform(field, terra::crs(bio$LAI)), "data/cerzoo_f3_field.geojson",
             delete_dsn = file.exists("data/cerzoo_f3_field.geojson"), quiet = TRUE)
v <- terra::values(nn, na.rm = TRUE)
cat("pixels", length(v), " NNI median", round(median(v), 2),
    " zones (<0.9, 0.9-1.1, >1.1):", sum(v < 0.9), sum(v >= 0.9 & v <= 1.1), sum(v > 1.1), "\n")
cat("LAI median", round(median(terra::values(lai, na.rm = TRUE)), 2), "\n")
cat("cells", nrow(rx), " dose range", range(rx$dose), " area-weighted mean",
    round(stats::weighted.mean(rx$dose, rx$area_ha), 1), " field ha", round(sum(rx$area_ha), 2), "\n")
