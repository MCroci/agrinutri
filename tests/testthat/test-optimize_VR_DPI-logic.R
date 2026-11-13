# Unit tests for the deterministic layers of optimize_VR_DPI():
# compliance cap, NNI weighting, mass-balance water-filling, fallbacks and
# raster assembly. Rquefts::optApp() / fertApp() are mocked so the tests are
# fast and safe on every platform (optApp can segfault on some Windows
# builds); the real optApp path is exercised by test-optimize_VR_DPI.R.

.vr_field <- function(...) {
  fld <- list(
    crop = "Grano duro (granella)",
    expected_yield_tons_ha = 6,
    ccp = "Spring-summer crop 100-130 days",
    sand = 15.5, clay = 18.5, Ntot = 1.5, SOM = 2, CN = 7.73,
    oxygen_availability = "Slow",
    winter_rain = 150, start_spring_rain = 0,
    prev_crop = "Winter cereals straw removal",
    source = "Cattle slurry", fertorg_frequency = "every year",
    location = "Isolated plain",
    forg_quantity = 0, organic_previous_year_N = 0, E_to_D = TRUE
  )
  utils::modifyList(fld, list(...))
}

# Field-level DPI dose computed exactly as optimize_VR_DPI() does.
.vr_dpi_dose <- function(fld) {
  fi <- fld[names(fld) %in% names(formals(N_balance))]
  b <- do.call(N_balance, fi)[1L, ]
  calculate_N_fertilization(b)
}

.vr_rast <- function(vals, nr = 3L, nc = 3L) {
  terra::rast(nrows = nr, ncols = nc, xmin = 0, xmax = 10 * nc,
              ymin = 0, ymax = 10 * nr, crs = "EPSG:32632", vals = vals)
}

# optimize_VR_DPI() must not emit any warning on these well-formed inputs
# (it used to warn "[readValues] raster has no values" from .fill_rst).
.quiet_rv <- function(expr) expr

# get_MAS() is mocked to a fixed MAS (default 200 kg N/ha) so these tests pin
# the redistribution logic independently of the MAS reference values.
.mock_rquefts <- function(N = 100, P = 10, K = 20, env = parent.frame(),
                          fail_opt = FALSE, fail_fert = FALSE, mas = 200) {
  testthat::local_mocked_bindings(
    get_MAS = function(crop = NULL, ...) {
      if (is.na(mas)) return(NULL)
      data.frame(crop = crop, mas_N = mas)
    },
    .env = env
  )
  testthat::local_mocked_bindings(
    optApp = function(qm, fertilizers, dm_crop_value, ...) {
      if (fail_opt) stop("mock optApp failure")
      list(N = N, P = P, K = K)
    },
    fertApp = function(nutrients, fertilizers, price, ...) {
      if (fail_fert) stop("mock fertApp failure")
      data.frame(n_cells = nrow(nutrients), mean_N = mean(nutrients$N))
    },
    .package = "Rquefts",
    .env = env
  )
}

test_that("optimize_VR_DPI preserves the economic optimum as field mean when it is below the cap", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(N = 100, P = 10, K = 20)

  fld <- .vr_field()
  nni <- seq(0.6, 1.0, length.out = 9)
  out <- .quiet_rv(optimize_VR_DPI(fld, .vr_rast(nni), prices = list(p_y = 300)))

  dpi <- .vr_dpi_dose(fld)
  cmp <- out$compliance
  expect_equal(cmp$DPI_cap_kg_ha, dpi)
  expect_equal(cmp$MAS_kg_ha, 200)                 # mocked MAS
  expect_true(cmp$ZVN_active)
  expect_equal(cmp$ZVN_cap_kg_ha, 170)
  expect_equal(cmp$applied_cap_kg_ha, min(dpi, 200, 170))
  expect_false(cmp$regulatory_binding)             # EONR 100 < cap
  expect_equal(cmp$field_target_kg_ha, 100)
  expect_true(cmp$mass_balance_ok)

  n <- terra::values(out$N_prescription, mat = FALSE)
  expect_equal(mean(n), 100, tolerance = 1e-6)
  expect_equal(cmp$mean_field_N, mean(n))
  expect_equal(cmp$max_cell_N, max(n))
  # Linear NNI weights: w = 1 - (NNI - min)/range, normalised to mean 1.
  w <- 1 - (nni - min(nni)) / diff(range(nni))
  expect_equal(n, 100 * w / mean(w), tolerance = 1e-8)
  expect_true(all(diff(n) <= 0))                   # higher NNI -> less N
  expect_equal(n[9], 0)

  expect_equal(names(out$N_prescription), "N_kg_ha")
  expect_equal(names(out$P_prescription), "P2O5_kg_ha")
  expect_equal(names(out$K_prescription), "K2O_kg_ha")
  expect_equal(unique(terra::values(out$P_prescription, mat = FALSE)), 10 * 2.291)
  expect_equal(unique(terra::values(out$K_prescription, mat = FALSE)), 20 * 1.205)

  ec <- out$economics
  expect_equal(ec$p_y, 300)
  expect_equal(ec$dm_eur_per_kg, 0.3)
  expect_equal(ec$eonr_mean_N, 100)
  expect_equal(ec$mean_dose, mean(n))
  # fertApp receives one nutrient row per valid cell
  expect_equal(out$fertilizer_mix$n_cells, 9L)
  expect_equal(out$fertilizer_mix$mean_N, 100, tolerance = 1e-6)
})

test_that("optimize_VR_DPI caps at the regulatory budget and water-fills under the MAS", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(N = 400)

  fld <- .vr_field()
  nni <- seq(0.5, 1.0, length.out = 9)            # w_norm spans 2 .. 0
  out <- .quiet_rv(optimize_VR_DPI(fld, .vr_rast(nni)))
  cmp <- out$compliance
  cap <- min(.vr_dpi_dose(fld), 200, 170)

  expect_true(cmp$regulatory_binding)
  expect_equal(cmp$field_target_kg_ha, cap)
  n <- terra::values(out$N_prescription, mat = FALSE)
  expect_true(all(n >= 0))
  expect_lte(max(n), 200 + 1e-9)                  # MAS ceiling per cell
  expect_equal(mean(n), cap, tolerance = 0.05)    # field mean preserved
  expect_true(cmp$mass_balance_ok)
  expect_true(all(diff(n) <= 1e-9))
  expect_equal(out$economics$p_y, 280)            # default price
})

test_that("optimize_VR_DPI flags a broken mass balance when the MAS cannot absorb the target", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(N = 400)

  # Only one cell has a non-zero weight: it is clipped to the MAS and no free
  # cell can take the remaining mass.
  nni <- c(0.5, rep(1, 8))
  out <- .quiet_rv(optimize_VR_DPI(.vr_field(), .vr_rast(nni)))
  n <- terra::values(out$N_prescription, mat = FALSE)
  expect_equal(n, c(200, rep(0, 8)))
  expect_false(out$compliance$mass_balance_ok)
})

test_that("optimize_VR_DPI: uniform NNI gives a flat map; ZVN switch changes the cap", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(N = 400)

  fld <- .vr_field(expected_yield_tons_ha = 10)    # DPI dose above 170
  dpi <- .vr_dpi_dose(fld)
  skip_if(dpi <= 170, "DPI dose not above the ZVN cap for this fixture")

  on  <- .quiet_rv(optimize_VR_DPI(fld, .vr_rast(rep(0.8, 4), 2, 2), zvn = TRUE))
  off <- .quiet_rv(optimize_VR_DPI(fld, .vr_rast(rep(0.8, 4), 2, 2), zvn = FALSE))

  expect_equal(on$compliance$applied_cap_kg_ha, 170)
  expect_equal(off$compliance$applied_cap_kg_ha, min(dpi, 200))
  expect_true(is.na(off$compliance$ZVN_cap_kg_ha))
  expect_false(off$compliance$ZVN_active)
  # zero-range NNI -> all weights 1 -> flat prescription at the cap
  expect_equal(unique(terra::values(on$N_prescription, mat = FALSE)), 170)
})

test_that("optimize_VR_DPI keeps NA cells as NA and ignores them in the mean", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(N = 90)

  nni <- c(0.7, NA, 0.9, 1.0)
  out <- .quiet_rv(optimize_VR_DPI(.vr_field(), .vr_rast(nni, 2, 2)))
  n <- terra::values(out$N_prescription, mat = FALSE)
  expect_true(is.na(n[2]))
  expect_equal(mean(n, na.rm = TRUE), 90, tolerance = 1e-6)
  expect_equal(out$fertilizer_mix$n_cells, 3L)
})

test_that("optimize_VR_DPI falls back to the DPI budget when optApp fails", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(fail_opt = TRUE)

  fld <- .vr_field()
  expect_warning(
    out <- .quiet_rv(optimize_VR_DPI(fld, .vr_rast(rep(0.8, 4), 2, 2))),
    "failed for 4 of 4"
  )
  cap <- min(.vr_dpi_dose(fld), 200, 170)
  expect_equal(out$economics$eonr_mean_N, cap)
  expect_equal(out$compliance$field_target_kg_ha, cap)
  expect_false(out$compliance$regulatory_binding)
  expect_true(all(is.na(terra::values(out$P_prescription, mat = FALSE))))
})

test_that("optimize_VR_DPI returns an empty mix with a warning when fertApp fails", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(fail_fert = TRUE)
  expect_warning(
    out <- .quiet_rv(optimize_VR_DPI(.vr_field(), .vr_rast(rep(0.8, 4), 2, 2))),
    "fertApp\\(\\): mock fertApp failure"
  )
  expect_s3_class(out$fertilizer_mix, "data.frame")
  expect_equal(nrow(out$fertilizer_mix), 0L)
})

test_that("optimize_VR_DPI accepts crop_params as a list or a label, and warns when no MAS", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts(N = 50, mas = NA)

  # No MAS (mocked get_MAS() -> NULL). Soybean is not in the QUEFTS IT table,
  # so explicit QUEFTS crop parameters are required.
  fld <- .vr_field(crop = "Soybean (grain)", expected_yield_tons_ha = 4)
  expect_warning(
    out <- .quiet_rv(optimize_VR_DPI(fld, .vr_rast(rep(0.9, 4), 2, 2),
                                     crop_params = Rquefts::quefts_crop("Soyabean"))),
    "MAS not found"
  )
  expect_true(is.na(out$compliance$MAS_kg_ha))
  expect_equal(out$compliance$applied_cap_kg_ha,
               min(.vr_dpi_dose(fld), 170))      # only DPI and ZVN remain

  .mock_rquefts(N = 50)
  out2 <- .quiet_rv(optimize_VR_DPI(.vr_field(), .vr_rast(rep(0.9, 4), 2, 2),
                                    crop_params = "Grano duro (granella)",
                                    fertilizers = data.frame(
                                      name = "Urea", N = 46, P = 0, K = 0,
                                      price_kg = 0.5)))
  expect_equal(out2$compliance$field_target_kg_ha, 50)
})

test_that("optimize_VR_DPI validates its inputs", {
  skip_if_not_installed("Rquefts")
  skip_if_not_installed("terra")
  .mock_rquefts()
  fld <- .vr_field()
  r <- .vr_rast(rep(0.8, 4), 2, 2)

  expect_error(optimize_VR_DPI(fld, .vr_rast(rep(NA_real_, 4), 2, 2)),
               "No finite NNI cells")
  expect_error(optimize_VR_DPI(fld, r, fertilizers = data.frame(name = "x", N = 1)),
               "columns name, N, P, K")
  expect_error(optimize_VR_DPI(fld, r,
                               fertilizers = data.frame(name = "x", N = 1, P = 0, K = 0)),
               "price_kg")
})
