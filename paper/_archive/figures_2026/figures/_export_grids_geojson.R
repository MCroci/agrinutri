# Export the 5 CERZOO Field 3 prescription strategies (lab exercise 07) to a
# single GeoJSON so the publication figure can be drawn with geopandas/matplotlib.
suppressWarnings(suppressMessages(library(sf)))
lab <- "C:/Users/michele.croci/OneDrive - Universita Cattolica del Sacro Cuore/rds/teaching/2027/Fondamenti di agricoltura di precisione/lab-agricoltura-di-precisione"
if (!dir.exists(lab))
  lab <- normalizePath(file.path("C:/Users/michele.croci/OneDrive - Università Cattolica del Sacro Cuore",
    "rds/teaching/2027/Fondamenti di agricoltura di precisione/lab-agricoltura-di-precisione"), mustWork = TRUE)
g <- readRDS(file.path(lab, "output/07_prescrizione_VRT/grids.rds"))
labs_en <- c(uniforme = "Uniform",
             calibrazione_pendenza_negativa = "Calibration (inverse)",
             calibrazione_pendenza_positiva = "Calibration (direct)",
             classi = "Quantile classes",
             nni = "NNI zones")
mk <- function(k) { s <- sf::st_transform(g[[k]], 3857); data.frame(strategy = labs_en[[k]],
  dose = as.numeric(s$dose), geometry = sf::st_geometry(s)) |> sf::st_as_sf() }
out <- do.call(rbind, lapply(names(labs_en), mk))
dst <- "paper/figures/cerzoo_strategies.geojson"
if (file.exists(dst)) file.remove(dst)
sf::st_write(out, dst, quiet = TRUE)
cat("wrote", dst, "with", nrow(out), "strips x", length(labs_en), "strategies\n")
