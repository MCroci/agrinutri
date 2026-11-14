# Data for Figs. 4-5: a satellite-delineated maize field of the Piacenza plain (Fields of The World
# boundary, data/rs_field.geojson) and the Sentinel-2 L2A scene of 13 August 2024, clipped to it.
# Run from paper/softwarex/ after fig2_farm.R:  Rscript fig4_data.R
# The scene is read from the public Microsoft Planetary Computer STAC catalogue (anonymous SAS token),
# windowed to the field, 20 m bands resampled to the 10 m grid (nearest), offset of processing
# baseline >= 04.00 removed (reflectance x 10000, harmonised).
suppressMessages(pkgload::load_all("../..", quiet = TRUE))
field <- sf::st_read("data/rs_field.geojson", quiet = TRUE)
PC <- "https://planetarycomputer.microsoft.com/api"
bb <- sf::st_bbox(sf::st_transform(field, 4326))
hit <- jsonlite::fromJSON(sprintf("%s/stac/v1/search?collections=sentinel-2-l2a&bbox=%s&datetime=2024-08-13T00:00:00Z/2024-08-13T23:59:59Z",
                                  PC, paste(round(bb, 5), collapse = ",")), simplifyVector = FALSE)$features
stopifnot(length(hit) >= 1); it <- hit[[1]]
tok <- jsonlite::fromJSON(paste0(PC, "/sas/v1/token/sentinel-2-l2a"))$token
B <- c("B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12", "SCL")
cog <- function(b) terra::rast(paste0("/vsicurl/", it$assets[[b]]$href, "?", tok))
ref <- cog("B02")
fv <- terra::vect(sf::st_transform(field, terra::crs(ref)))
win <- terra::crop(ref, terra::ext(fv) + 30, snap = "out")
x <- terra::rast(lapply(B, function(b) { r <- terra::crop(cog(b), terra::ext(win) + 20, snap = "out")
  if (!isTRUE(all.equal(terra::res(r), terra::res(win)))) r <- terra::resample(r, win, method = "near") else r <- terra::crop(r, win)
  r }))
names(x) <- B
off <- if (as.numeric(it$properties$`s2:processing_baseline`) >= 4) 1000 else 0
scl <- x[["SCL"]]
x <- terra::clamp(x[[1:10]] - off, lower = 0, values = TRUE)
x <- terra::mask(x, scl >= 4 & scl <= 5, maskvalues = FALSE)   # SCL 4-5: vegetation, bare soil
cat(it$id, "| cloud", round(it$properties$`eo:cloud_cover`, 1), "% | offset", off, "
")
s2 <- "data/rs_s2_20240813.tif"
terra::writeRaster(x, s2, overwrite = TRUE, NAflag = 0, datatype = "INT2U")

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
