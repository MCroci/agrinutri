# Shared configuration for the CERZOO case study of the SAT paper.
# Run every script from the package root:  Rscript paper/sat/01_balance.R
suppressMessages({ library(terra); library(sf) })
pkgload::load_all(".", quiet = TRUE)               # NFert from the working tree

ROOT <- Sys.getenv("PRESTO_DEPLOY", "C:/Users/michele.croci/Desktop/presto-deploy")
RAW  <- file.path(ROOT, "data/raw/cerzoo")
S2   <- file.path(ROOT, "data/rasters/downloads_cerzoo_multiband")
# Scenario: "reference" = DPI reference weather (winter rain 150 mm, no February rain, i.e. no
# leaching term), the main case study; "season" = the measured 2024-25 rainfall (301 and 98 mm)
# and the recorded previous crops, a sensitivity run. Outputs of "season" go to a subfolder.
SCENARIO <- Sys.getenv("SAT_SCENARIO", "reference")
stopifnot(SCENARIO %in% c("reference", "season"))
SUB  <- c(if (SCENARIO == "season") "season", if (Sys.getenv("SAT_SOIL_RUN", "definitive") == "run1") "run1")
OUT  <- do.call(file.path, as.list(c("paper/sat/out",  SUB)))   # sensitivity runs go to subfolders
DAT  <- do.call(file.path, as.list(c("paper/sat/data", SUB)))
dir.create(OUT, FALSE, TRUE); dir.create(DAT, FALSE, TRUE)

# ---- soil input layer -------------------------------------------------------
# "definitive": 0_RISULTATI_DEFINITIVI (8 June 2026; RF models without coordinates,
#   plausibility-constrained); hold-out error = leave-one-point-out RMSE of its CSV.
# "run1": 1_spazializzazione (7 June 2026; XGBoost / LightGBM); hold-out error =
#   leave-one-field-out RMSE, the run the area of applicability was computed for.
SOIL_RUN <- Sys.getenv("SAT_SOIL_RUN", "definitive")
SOIL_DIR <- file.path(ROOT, "figures/cerzoo_soil")
RMSE <- switch(SOIL_RUN,
  definitive = c(clay = 2.8994, sand = 3.4685, toc = 0.1032, tn = 0.0130),   # % (clay, sand, TOC, TN)
  run1       = c(clay = 3.2466, sand = 4.4433, toc = 0.1001, tn = 0.0151),
  stop("SAT_SOIL_RUN must be 'definitive' or 'run1'"))
RHO <- c(clay_sand = -0.644, toc_tn = 0.904)       # empirical correlations of the 20 samples

soil_file <- function(slug, kind) {
  if (SOIL_RUN == "definitive")
    return(file.path(SOIL_DIR, "0_RISULTATI_DEFINITIVI", sprintf("%s_%s.tif", slug, kind)))
  f <- list.files(file.path(SOIL_DIR, "1_spazializzazione/geotiff", slug),
                  pattern = paste0(kind, "[.]tif$"), full.names = TRUE)
  stopifnot(length(f) == 1L); f
}

# ---- fields and management --------------------------------------------------
# One row per field; the management columns are the NFert inputs and are edited
# in cerzoo_field_inputs*.csv (see the README for how each value was chosen).
AOI <- st_transform(st_read(file.path(RAW, "aoi_multi_cerzoo_fields.geojson"), quiet = TRUE), 32632)
FIELDS <- merge(sf::st_drop_geometry(AOI)[, c("field_id", "area_id")],
                read.csv(if (SCENARIO == "season") "paper/sat/cerzoo_field_inputs_season.csv" else "paper/sat/cerzoo_field_inputs.csv",
                         stringsAsFactors = FALSE),
                by = "field_id", sort = FALSE)
FIELDS$label <- paste0("F", FIELDS$field_id)
AOI$label <- paste0("F", AOI$field_id)
AOI$crop_group <- ifelse(AOI$field_id == 5, "wheat", "maize")

# balance of one field for given soil vectors (kg N/ha; no current-year organic credit)
dose_fn <- function(fi, clay, sand, toc, tn) {
  vapply(seq_along(clay), function(i) {
    b <- suppressWarnings(N_balance(
      expected_yield_tons_ha = fi$yield, crop = fi$crop, ccp = fi$ccp,
      sand = sand[i], clay = clay[i], Ntot = tn[i] * 10, SOM = toc[i] * 1.724,
      CN = toc[i] / tn[i], oxygen_availability = fi$oxygen,
      winter_rain = fi$winter_rain, start_spring_rain = fi$start_spring_rain,
      prev_crop = fi$prev_crop, source = "None", fertorg_frequency = "every year",
      location = fi$location, forg_quantity = 0))
    calculate_N_fertilization(b)
  }, numeric(1))
}

# correlated Gaussian soil perturbation (Section 2.6): clay-sand and TOC-TN pairs,
# closure sand <= 98 - clay, TOC and TN floored at small positive values
perturb_soil <- function(clay, sand, toc, tn, n = length(clay), scale = 1,
                         groups = c("texture", "cn"), rmse = RMSE, rho = RHO) {
  corr_pair <- function(r) { z1 <- rnorm(n); list(z1, r * z1 + sqrt(1 - r^2) * rnorm(n)) }
  if ("texture" %in% groups) {
    z <- corr_pair(rho[["clay_sand"]])
    clay <- pmin(pmax(clay + rmse[["clay"]] * scale * z[[1]], 1), 90)
    sand <- pmin(pmax(sand + rmse[["sand"]] * scale * z[[2]], 1), 98 - clay)
  }
  if ("cn" %in% groups) {
    z <- corr_pair(rho[["toc_tn"]])
    toc <- pmax(toc + rmse[["toc"]] * scale * z[[1]], 0.05)
    tn  <- pmax(tn  + rmse[["tn"]]  * scale * z[[2]], 0.005)
  }
  list(clay = clay, sand = sand, toc = toc, tn = tn)
}

# soil maps at 10 m masked to the fields (clay, sand, TOC, TN in %)
read_soil <- function() {
  r <- c(rast(soil_file("clay_content", "prediction")), rast(soil_file("sand_content", "prediction")),
         rast(soil_file("organic_carbon", "prediction")), rast(soil_file("total_nitrogen", "prediction")))
  names(r) <- c("clay", "sand", "toc", "tn")
  fid <- rasterize(vect(AOI), r[[1]], field = "field_id")
  names(fid) <- "field"
  mask(c(r, fid), fid)
}
