# Direct tests for previously-untested exported functions.
# Normative constants (MAS) are checked exactly against DPI 2026 / 2025;
# computed quantities are checked for structure and plausible ranges.

# ---------------------------------------------------------------------------
# get_MAS() / check_MAS() — DPI Allegato 9 benchmark (Reg. reg. 2/2024)
# ---------------------------------------------------------------------------
test_that("get_MAS returns DPI 2026 MAS values (Fert_Office v1.26 MAS sheet)", {
  # Column "MAS" of Fert_Office v1.26 (Reg. reg. 2/2024), not "teorico massimo"
  expect_equal(get_MAS("Mais da granella 500-700 (granella)")$mas_N, 280L)
  expect_equal(get_MAS("Mais trinciato classe 700")$mas_N,           280L)
  expect_equal(get_MAS("Grano duro (granella)")$mas_N,               190L)
  expect_equal(get_MAS("Grano tenero FF (granella)")$mas_N,          190L)
  expect_equal(get_MAS("Grano tenero FP/FPS (granella)")$mas_N,      180L)
  expect_equal(get_MAS("Orzo (granella)")$mas_N,                     150L)
  expect_equal(get_MAS("Melo frutti, legno e foglie")$mas_N,         120L)
  expect_equal(get_MAS("Actinidia polpa verde frutti, legno e foglie")$mas_N, 150L)
  expect_equal(get_MAS("Soia (granella)")$mas_N,                      30L)
})

test_that("get_MAS maps legacy generic DPI names to a MAS row", {
  expect_equal(get_MAS("Mais da granella")$crop, "Grain maize 500-700 (grain)")
  expect_equal(get_MAS("Mais da insilato")$crop, "Silage maize (class 700)")
  expect_equal(get_MAS("Mais trinciato (classe 700)")$mas_N, 280L)
  expect_equal(get_MAS("Frumento tenero (granella)")$mas_N, 180L)
})

test_that("get_MAS edition 2025 keeps the Guida 2025 ZVN table", {
  expect_equal(get_MAS("Mais da granella", edition = "2025")$mas_N,           280L)
  expect_equal(get_MAS("Frumento tenero (granella)", edition = "2025")$mas_N, 180L)
})

test_that("get_MAS accepts English, Italian and accent-folded names", {
  expect_equal(get_MAS("Durum wheat (grain)")$mas_N, 190L)
  expect_equal(get_MAS("durum wheat (grain)")$mas_N, 190L)
  expect_identical(get_MAS("Grano duro (granella)")$crop,
                   get_MAS("Durum wheat (grain)")$crop)
})

test_that("get_MAS() with no crop returns the full table", {
  tab <- get_MAS()
  expect_s3_class(tab, "data.frame")
  expect_true(all(c("crop", "crop_it", "mas_N") %in% names(tab)))
  expect_gt(nrow(tab), 200L)
  expect_false(anyDuplicated(tab$crop) > 0)
})

test_that("get_MAS warns and returns NULL for an unknown crop", {
  expect_warning(res <- get_MAS("Crop That Does Not Exist"))
  expect_null(res)
})

test_that("check_MAS flags doses above and within the MAS", {
  expect_true(check_MAS("Mais da granella", 250)$ok)          # 250 <= 280
  expect_false(check_MAS("Mais da granella", 300)$ok)         # 300 >  280
  expect_false(check_MAS("Grano duro (granella)", 200)$ok)    # 200 >  190
  expect_true(check_MAS("Grano duro (granella)", 190)$ok)
})

test_that("check_MAS caps soya at 30 kg N/ha", {
  res <- check_MAS("Soia", 60)
  expect_false(res$ok)
  expect_equal(res$mas_N, 30L)
})

test_that("check_MAS treats a crop with no MAS_N as compliant", {
  res <- check_MAS("Leaf beet", 60)
  expect_true(res$ok)
  expect_true(is.na(res$mas_N))
})

# ---------------------------------------------------------------------------
# farm_balance() — enrich an sf farm with N_target / MAS_cap / N_total_kg
# ---------------------------------------------------------------------------
test_that("farm_balance enriches the bundled example farm", {
  skip_if_not_installed("sf")
  ex <- system.file("extdata/example_farm.geojson", package = "NFert")
  skip_if(!nzchar(ex), "no bundled example_farm.geojson")

  farm <- farm_balance(ex)
  expect_s3_class(farm, "sf")
  expect_true(all(c("N_target", "MAS_cap", "MAS_ok", "balance_error") %in% names(farm)))
  # At least one plot should produce a finite agronomic target.
  expect_true(any(is.finite(farm$N_target)))
  # MAS_ok must be the logical comparison N_target <= MAS_cap where both finite.
  fin <- is.finite(farm$N_target) & is.finite(farm$MAS_cap)
  expect_equal(farm$MAS_ok[fin], (farm$N_target <= farm$MAS_cap)[fin])
  # N_total_kg = N_target * area_ha when area_ha is present.
  if ("area_ha" %in% names(farm) && any(fin)) {
    i <- which(fin)[1]
    expect_equal(farm$N_total_kg[i],
                 round(farm$N_target[i] * as.numeric(farm$area_ha[i]), 1))
  }
})

# ---------------------------------------------------------------------------
# compute_vi() — vegetation-index engine (terra SpatRaster)
# ---------------------------------------------------------------------------
test_that("compute_vi computes the correct NDVI from known bands", {
  skip_if_not_installed("terra")
  r <- terra::rast(nrows = 2, ncols = 2, xmin = 0, xmax = 2, ymin = 0, ymax = 2,
                   nlyrs = 4, crs = "EPSG:32632")
  names(r) <- c("B03", "B04", "B05", "B08")
  terra::values(r) <- cbind(rep(0.1, 4), rep(0.2, 4), rep(0.3, 4), rep(0.6, 4))
  ndvi <- compute_vi(r, "NDVI")              # (0.6 - 0.2) / (0.6 + 0.2) = 0.5
  expect_s4_class(ndvi, "SpatRaster")
  expect_equal(unique(round(terra::values(ndvi, mat = FALSE), 6)), 0.5)
  expect_equal(names(ndvi), "NDVI")
})

test_that("compute_vi maps bands by index and errors on a missing band", {
  skip_if_not_installed("terra")
  r <- terra::rast(nrows = 2, ncols = 2, nlyrs = 2, crs = "EPSG:32632")
  names(r) <- c("red", "nir")
  terra::values(r) <- cbind(rep(0.2, 4), rep(0.6, 4))
  vi <- compute_vi(r, "NDVI", bands = list(red = 1, nir = 2))
  expect_equal(unique(round(terra::values(vi, mat = FALSE), 6)), 0.5)
  expect_error(compute_vi(r, "NDRE"))        # red_edge band not provided/found
})

# ---------------------------------------------------------------------------
# compute_NNI() / diagnose_N_status()
# ---------------------------------------------------------------------------
test_that("compute_NNI scalar matches the critical-N dilution curve", {
  cv <- critical_N_curve("wheat")
  W  <- 2.5
  Nc <- cv$a * W^(-cv$b)
  expect_equal(compute_NNI(3.2, W, crop = "wheat", is_percent = TRUE),
               3.2 / Nc, tolerance = 1e-6)
})

test_that("diagnose_N_status returns the three NNI classes", {
  defic <- diagnose_N_status(1.2, 4, crop = "wheat", is_percent = TRUE)
  optim <- diagnose_N_status(3.0, 2.5, crop = "wheat", is_percent = TRUE)
  expect_true(defic$class %in% 1:3)
  expect_true(optim$class %in% 1:3)
  expect_lt(defic$NNI, optim$NNI)
})

# ---------------------------------------------------------------------------
# variable_rate_N() — agronomic mean preserved, MAS cap respected
# ---------------------------------------------------------------------------
test_that("variable_rate_N preserves the field mean and respects the MAS cap", {
  skip_if_not_installed("terra")
  set.seed(42)
  ndvi <- terra::rast(nrows = 10, ncols = 10, xmin = 0, xmax = 100,
                      ymin = 0, ymax = 100, crs = "EPSG:32632")
  terra::values(ndvi) <- runif(100, 0.3, 0.8)

  vr <- variable_rate_N(ndvi, n_dose = 142, method = "calibration", plot = FALSE)
  expect_s4_class(vr$rate_raster, "SpatRaster")
  expect_lt(abs(vr$mean_kg_ha - 142), 1)

  vc <- variable_rate_N(ndvi, n_dose = 142, method = "holland",
                        mas_cap = 150, plot = FALSE)
  expect_lte(vc$max_kg_ha, 150 + 1e-6)
})

# ---------------------------------------------------------------------------
# spatial_N_balance() — pixel-wise balance to a SpatRaster
# ---------------------------------------------------------------------------
test_that("spatial_N_balance returns a SpatRaster with an N_to_apply layer", {
  skip_if_not_installed("terra")
  soil <- terra::rast(nrows = 6, ncols = 6, xmin = 0, xmax = 60, ymin = 0,
                      ymax = 60, nlyrs = 5, crs = "EPSG:32632")
  names(soil) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
  set.seed(1)
  terra::values(soil) <- cbind(runif(36, 1, 1.6), runif(36, 1.5, 2.5),
                               runif(36, 15, 25), runif(36, 30, 50),
                               runif(36, 7, 10))
  nm <- spatial_N_balance(
    soil, expected_yield_tons_ha = 6,
    crop = "Grano duro (pianta intera)",
    ccp  = "Spring-summer crop 100-130 days",
    winter_rain = 150, start_spring_rain = 0,
    prev_crop = "Maize stalks removed", source = "None", forg_quantity = 0)
  expect_s4_class(nm, "SpatRaster")
  expect_true("N_to_apply" %in% names(nm))

  # The pixel dose is the dose of N_balance() + calculate_N_fertilization()
  v <- terra::values(soil)[7, ]
  b <- N_balance(expected_yield_tons_ha = 6, crop = "Grano duro (pianta intera)",
                 ccp = "Spring-summer crop 100-130 days", sand = v[["Sand"]],
                 clay = v[["Clay"]], Ntot = v[["TN"]], SOM = v[["SOM"]],
                 CN = v[["CNratio"]], winter_rain = 150, start_spring_rain = 0,
                 prev_crop = "Maize stalks removed", source = "None",
                 forg_quantity = 0)
  expect_equal(terra::values(nm[["N_to_apply"]])[7], calculate_N_fertilization(b))
})

# ---------------------------------------------------------------------------
# dose_standard_PK() — Scheda a dose Standard P/K
# ---------------------------------------------------------------------------
test_that("dose_standard_PK returns finite base/final P and K doses", {
  res <- dose_standard_PK(crop = "Grano duro (pianta intera)",
                          soil_P_class = "normal", soil_K_class = "normal")
  expect_true(all(c("dose_base_P2O5", "dose_base_K2O",
                    "dose_final_P2O5", "dose_final_K2O") %in% names(res)))
  expect_true(is.finite(res$dose_final_P2O5) && res$dose_final_P2O5 >= 0)
  expect_true(is.finite(res$dose_final_K2O)  && res$dose_final_K2O  >= 0)
})

test_that("dose_standard_PK increments raise the P2O5 dose", {
  base <- dose_standard_PK(crop = "Grano duro (pianta intera)")
  bump <- dose_standard_PK(crop = "Grano duro (pianta intera)",
                           P_increments = c(extra = 20))
  expect_equal(bump$dose_final_P2O5, base$dose_final_P2O5 + 20)
})

# ---------------------------------------------------------------------------
# export_prescription() / export_prescription_all()
# ---------------------------------------------------------------------------
test_that("export_prescription writes a readable GeoJSON", {
  skip_if_not_installed("sf")
  poly <- sf::st_sf(
    dose = c(120, 160),
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(c(0, 0), c(100, 0), c(100, 100), c(0, 100), c(0, 0)))),
      sf::st_polygon(list(rbind(c(100, 0), c(200, 0), c(200, 100), c(100, 100), c(100, 0)))),
      crs = 32632))
  out <- file.path(tempdir(), "rx_test.geojson")
  if (file.exists(out)) file.remove(out)
  export_prescription(poly, out, format = "geojson", dose_field = "dose")
  expect_true(file.exists(out))
  back <- sf::st_read(out, quiet = TRUE)
  expect_s3_class(back, "sf")
  expect_gt(nrow(back), 0L)
})

test_that("export_prescription_all writes the requested formats", {
  skip_if_not_installed("sf")
  poly <- sf::st_sf(
    dose = c(120, 160),
    geometry = sf::st_sfc(
      sf::st_polygon(list(rbind(c(0, 0), c(100, 0), c(100, 100), c(0, 100), c(0, 0)))),
      sf::st_polygon(list(rbind(c(100, 0), c(200, 0), c(200, 100), c(100, 100), c(100, 0)))),
      crs = 32632))
  od <- file.path(tempdir(), "rx_all")
  out <- suppressWarnings(           # GDAL emits a benign probe warning for .shp
    export_prescription_all(poly, od, basename = "t",
                            formats = c("geojson", "shp"),
                            dose_field = "dose"))
  expect_true(file.exists(out$geojson))
  expect_true(file.exists(out$shp))
})
