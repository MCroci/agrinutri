# End-to-end test of the Sentinel-2 -> NNI pipeline.
#
# `inst/extdata/sentinel-2/S2_field001_20240711.tif` is a tiny (~5 KB) 10-band
# L2A reflectance subset used here as a plumbing check: it is a sparse / mostly
# bare-soil scene (NDVI ~0.13), so its NNI is legitimately near-empty and these
# tests only assert that the pipeline runs and returns the right structure.
# The plausible-value regression (non-empty NNI, LAI ~3.5) is exercised on the
# vegetated CERZOO scene `S2_cerzoo_field3_20240813.tif` further down.
#
# Both stages drive `estimate_biophysical()` against the bundled GPR JSON models
# in `inst/extdata/SENTINEL2_L2A_*.json`. Tests are skipped if the suggested
# packages `terra` or `jsonlite` are not installed.

scene_path <- system.file("extdata/sentinel-2/S2_field001_20240711.tif",
                          package = "agrinutri")

test_that("Sentinel-2 demo scene is bundled", {
  expect_true(nzchar(scene_path))
  expect_true(file.exists(scene_path))
})

test_that("estimate_biophysical -> compute_NNI_from_S2 runs end-to-end", {
  skip_if_not_installed("terra")
  skip_if_not_installed("jsonlite")

  # 1. GPR retrieval (LAI / Cm / CNC_Cprot / FVC) -- output to tempdir
  out_dir <- file.path(tempdir(), "agrinutri-NNI-test")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  maps <- estimate_biophysical(
    raster_path = scene_path,
    output_dir  = out_dir,
    variables   = c("LAI", "Cm", "CNC_Cprot", "FVC"),
    block_rows  = 32         # small block, scene is tiny
  )

  expect_type(maps, "list")
  for (v in c("LAI", "Cm", "CNC_Cprot", "FVC")) {
    expect_s4_class(maps[[v]], "SpatRaster")
    # The on-disk path attribute must still point to a real file.
    expect_true(file.exists(attr(maps, "paths")[[v]]),
                info = sprintf("Missing on-disk file for %s", v))
  }

  # 2. NNI pipeline -- maize calibration
  nni <- compute_NNI_from_S2(
    lai_rast  = maps$LAI,
    cm_rast   = maps$Cm,
    cnc_rast  = maps$CNC_Cprot,
    cnc_layer = "CNC_Cprot",
    crop      = "maize",
    fvc       = maps$FVC
  )

  expect_type(nni, "list")
  for (lyr in c("W", "N_actual", "N_crit", "NNI", "zones", "mask"))
    expect_true(lyr %in% names(nni),
                info = sprintf("Missing layer: %s", lyr))

  # NNI raster must be SpatRaster
  expect_s4_class(nni$NNI,   "SpatRaster")
  expect_s4_class(nni$zones, "SpatRaster")

  # Sanity checks on values (only over masked-in pixels)
  nni_vals <- terra::values(nni$NNI, na.rm = TRUE)
  if (length(nni_vals) > 0) {
    expect_true(all(is.finite(nni_vals)))
    # Plausible range for a peak-summer scene, allow generous bounds.
    expect_true(min(nni_vals) >= 0)
    expect_true(max(nni_vals) <= 5)
  }

  zone_vals <- terra::values(nni$zones, na.rm = TRUE)
  if (length(zone_vals) > 0) {
    expect_setequal(unique(as.integer(zone_vals)),
                    intersect(1:3, unique(as.integer(zone_vals))))
  }
})

test_that("default scaling yields a plausible, non-empty NNI on the CERZOO scene", {
  skip_if_not_installed("terra")
  skip_if_not_installed("jsonlite")

  # Peak silage-maize scene (CERZOO Field 3, 13 Aug 2024). Stored as
  # offset-applied surface reflectance x10000, so the *default* scaling
  # (apply_offset = FALSE) must be used. This guards the reflectance-scaling
  # regression where an extra -1000 offset drove every pixel out of range and
  # returned an all-NA LAI / empty NNI (issue: empty operational NNI maps).
  cerzoo <- system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif",
                        package = "agrinutri")
  skip_if(!nzchar(cerzoo) || !file.exists(cerzoo),
          "CERZOO demo scene not bundled")

  out_dir <- file.path(tempdir(), "agrinutri-NNI-cerzoo")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  maps <- estimate_biophysical(
    raster_path = cerzoo,
    output_dir  = out_dir,
    variables   = c("LAI", "Cm", "CNC_Cprot", "FVC"),
    block_rows  = 64)              # default apply_offset = FALSE

  # LAI must not collapse to all-NA and should sit in a plausible canopy range.
  lai <- terra::values(maps$LAI, na.rm = TRUE)
  expect_gt(length(lai), 0)
  expect_gt(stats::median(lai), 2)
  expect_lt(stats::median(lai), 6)

  nni <- compute_NNI_from_S2(
    lai_rast  = maps$LAI,
    cm_rast   = maps$Cm,
    cnc_rast  = maps$CNC_Cprot,
    cnc_layer = "CNC_Cprot",
    crop      = "maize",
    fvc       = maps$FVC)

  # A vegetated field must retain pixels and produce a finite NNI map.
  kept <- sum(terra::values(nni$mask, na.rm = TRUE) > 0)
  expect_gt(kept, 0)
  nni_vals <- terra::values(nni$NNI, na.rm = TRUE)
  expect_gt(length(nni_vals), 0)
  expect_true(all(is.finite(nni_vals)))
  expect_gt(stats::median(nni_vals), 0.5)
  expect_lt(stats::median(nni_vals), 2)
})

test_that("estimate_biophysical warns on a DN scaling mismatch", {
  skip_if_not_installed("terra")
  skip_if_not_installed("jsonlite")

  cerzoo <- system.file("extdata/sentinel-2/S2_cerzoo_field3_20240813.tif",
                        package = "agrinutri")
  skip_if(!nzchar(cerzoo) || !file.exists(cerzoo),
          "CERZOO demo scene not bundled")

  out_dir <- file.path(tempdir(), "agrinutri-NNI-cerzoo-badscale")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Applying the baseline-04 offset to already-offset-applied reflectance
  # pushes the low visible bands negative -> the range guard masks the field.
  expect_warning(
    estimate_biophysical(
      raster_path  = cerzoo,
      output_dir   = out_dir,
      variables    = "LAI",
      apply_offset = TRUE,
      block_rows   = 64),
    "outside the 0-1.5 reflectance range")
})

test_that("compute_NNI_from_S2 errors on unknown crop", {
  skip_if_not_installed("terra")
  skip_if_not_installed("jsonlite")

  out_dir <- file.path(tempdir(), "agrinutri-NNI-test-bad-crop")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  maps <- estimate_biophysical(
    raster_path = scene_path,
    output_dir  = out_dir,
    variables   = c("LAI", "Cm", "CNC_Cprot"),
    block_rows  = 32
  )
  expect_error(
    compute_NNI_from_S2(
      lai_rast  = maps$LAI,
      cm_rast   = maps$Cm,
      cnc_rast  = maps$CNC_Cprot,
      cnc_layer = "CNC_Cprot",
      crop      = "Triticum_unobtainium"
    ),
    "Unknown crop"
  )
})
