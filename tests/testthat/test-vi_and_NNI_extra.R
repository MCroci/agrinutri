# compute_vi() index formulas / band handling, critical_N_curve(),
# compute_NNI() and diagnose_N_status() on scalars and rasters.

.s2 <- function(b03 = 0.1, b04 = 0.2, b05 = 0.3, b08 = 0.6, n = 4) {
  r <- terra::rast(nrows = 2, ncols = n / 2, xmin = 0, xmax = n / 2,
                   ymin = 0, ymax = 2, nlyrs = 4, crs = "EPSG:32632")
  names(r) <- c("B03", "B04", "B05", "B08")
  terra::values(r) <- cbind(rep(b03, n), rep(b04, n), rep(b05, n), rep(b08, n))
  r
}
.v1 <- function(r) unique(round(terra::values(r, mat = FALSE), 8))

test_that("compute_vi implements each index formula", {
  skip_if_not_installed("terra")
  s <- .s2()                                    # G 0.1, R 0.2, RE 0.3, NIR 0.6
  expect_equal(.v1(compute_vi(s, "NDRE")),  round((0.6 - 0.3) / 0.9, 8))
  expect_equal(.v1(compute_vi(s, "gndvi")), round(0.5 / 0.7, 8))
  expect_equal(.v1(compute_vi(s, "CIred")), 1)
  expect_equal(.v1(compute_vi(s, "MCARI")),
               round(((0.3 - 0.2) - 0.2 * (0.3 - 0.1)) * (0.3 / 0.2), 8))
  expect_equal(.v1(compute_vi(s, "MSAVI2")),
               round((2.2 - sqrt(2.2^2 - 8 * 0.4)) / 2, 8))
  expect_equal(names(compute_vi(s, "cired")), "CIred")
  expect_equal(names(compute_vi(s, "CI_red_edge")), "CIred")
  expect_equal(names(compute_vi(s, "CIred-edge")), "CIred")
  expect_equal(names(compute_vi(s, "msavi2")), "MSAVI2")
})

test_that("compute_vi rescales integer DN and clamps bounded indices", {
  skip_if_not_installed("terra")
  dn <- .s2(1000, 2000, 3000, 6000)
  expect_equal(.v1(compute_vi(dn, "NDVI", scale_factor = 10000)), 0.5)
  expect_equal(.v1(compute_vi(dn, "CIred", scale_factor = 10000)), 1)

  odd <- .s2(b04 = 0.1, b08 = -0.5)              # NDVI = -0.6 / -0.4 = 1.5
  expect_equal(.v1(compute_vi(odd, "NDVI")), 1)
  expect_equal(.v1(compute_vi(odd, "NDVI", clamp = FALSE)), 1.5)
})

test_that("compute_vi accepts a character band mapping and reports bad mappings", {
  skip_if_not_installed("terra")
  s <- .s2()
  expect_equal(.v1(compute_vi(s, "NDVI", bands = c(red = "B04", nir = "B08"))), 0.5)
  expect_error(compute_vi(s, "NDVI", bands = list(red = "B04")),
               "Missing band mapping for: nir")
  expect_error(compute_vi(s, "NDVI", bands = list(red = 9, nir = 4)),
               "out of range")
  expect_error(compute_vi(s, "NDVI", bands = list(red = "B99", nir = "B08")),
               "Band 'B99'")
  expect_error(compute_vi(), "`stack`")
  expect_error(compute_vi(matrix(1)), "must be a terra SpatRaster")
  expect_error(compute_vi(s), "`index` is required")
  expect_error(compute_vi(s, c("NDVI", "NDRE")), "`index` is required")
  expect_error(compute_vi(s, "EVI"), "must be one of")
})

test_that("critical_N_curve returns the published coefficients and synonyms", {
  expect_equal(critical_N_curve("wheat")[c("a", "b", "W_min")],
               list(a = 5.35, b = 0.44, W_min = 1.55))
  expect_identical(critical_N_curve("Grano duro"), critical_N_curve("wheat"))
  expect_equal(critical_N_curve("MAIS")$a, 3.40)
  expect_equal(critical_N_curve("riso")$b, 0.52)
  expect_equal(critical_N_curve("colza")$W_min, 1.55)
  expect_equal(critical_N_curve("ryegrass")$a, 4.80)
  expect_equal(critical_N_curve("sorgo")$b, 0.39)
  expect_equal(critical_N_curve("girasole")$reference, "Debaeke et al. 2012")
  expect_error(critical_N_curve(), "single character")
  expect_error(critical_N_curve(c("wheat", "maize")), "single character")
  expect_error(critical_N_curve("cotton"), "Unknown crop 'cotton'")
})

test_that("compute_NNI handles fractions, percentages, W_min clamp and custom curves", {
  cv <- critical_N_curve("maize")
  expect_equal(compute_NNI(0.028, 4, "maize"),
               compute_NNI(2.8, 4, "maize", is_percent = TRUE))
  expect_equal(compute_NNI(2.8, 4, "maize", is_percent = TRUE),
               2.8 / (cv$a * 4^(-cv$b)))
  # values > 1 with is_percent = FALSE are treated as percent, with a warning
  expect_warning(v <- compute_NNI(2.8, 4, "maize"), "Treating values as percent")
  expect_equal(v, 2.8 / (cv$a * 4^(-cv$b)))
  # biomass below W_min uses Nc(W_min)
  wh <- critical_N_curve("wheat")
  expect_equal(compute_NNI(c(3, 3), c(0.5, NA), "wheat", is_percent = TRUE),
               c(3 / (wh$a * wh$W_min^(-wh$b)), NA))
  # custom curve without W_min defaults to 1
  expect_equal(compute_NNI(2, 0.2, curve = list(a = 4, b = 0.5), is_percent = TRUE), 0.5)
  expect_error(compute_NNI(2, 2, curve = list(a = 4)), "must contain `a` and `b`")
})

test_that("compute_NNI works pixel-wise on SpatRasters", {
  skip_if_not_installed("terra")
  mk <- function(v) terra::rast(nrows = 1, ncols = length(v), xmin = 0,
                                xmax = length(v), ymin = 0, ymax = 1, vals = v,
                                crs = "EPSG:32632")
  n_frac <- mk(c(0.02, 0.03, 0.04))
  w <- mk(c(1, 3, 5))
  nni_r <- compute_NNI(n_frac, w, "wheat")
  expect_s4_class(nni_r, "SpatRaster")
  expect_equal(names(nni_r), "NNI")
  expect_equal(terra::values(nni_r, mat = FALSE),
               compute_NNI(c(0.02, 0.03, 0.04), c(1, 3, 5), "wheat"))
  # mixed raster / scalar inputs
  expect_equal(terra::values(compute_NNI(mk(c(2, 3)), 2, "wheat", is_percent = TRUE),
                             mat = FALSE),
               compute_NNI(c(2, 3), 2, "wheat", is_percent = TRUE))
  expect_warning(r_pct <- compute_NNI(mk(c(2, 3)), mk(c(2, 2)), "wheat"),
                 "raster has values > 1")
  expect_equal(terra::values(r_pct, mat = FALSE),
               compute_NNI(c(2, 3), 2, "wheat", is_percent = TRUE))
})

test_that("diagnose_N_status classifies scalars and vectors (thresholds inclusive)", {
  wh <- critical_N_curve("wheat")
  nc2 <- wh$a * 2^(-wh$b)
  N <- c(0.5, 0.9, 1.0, 1.1, 1.5, NA) * nc2      # NNI exactly at thresholds
  d <- diagnose_N_status(N, 2, "wheat", is_percent = TRUE)
  expect_equal(d$class, c(1L, 2L, 2L, 2L, 3L, NA))
  expect_equal(d$labels, c("deficient", "optimal", "optimal", "optimal",
                           "excessive", NA))
  expect_null(d$summary)
  expect_equal(d$thresholds, c(deficient = 0.9, excessive = 1.1))
  expect_identical(d$curve, wh)

  cu <- list(a = 4, b = 0.5, W_min = 1)
  dc <- diagnose_N_status(2, 4, curve = cu, is_percent = TRUE,
                          deficient_threshold = 0.8, excessive_threshold = 0.95)
  expect_equal(dc$NNI, 1)
  expect_equal(dc$class, 3L)
  expect_identical(dc$curve, cu)
  expect_error(diagnose_N_status(2, 2, "wheat", deficient_threshold = 1.2,
                                 excessive_threshold = 1.1),
               "must be <")
})

test_that("diagnose_N_status returns class rasters and a class summary", {
  skip_if_not_installed("terra")
  wh <- critical_N_curve("wheat")
  nc2 <- wh$a * 2^(-wh$b)
  N <- terra::rast(nrows = 1, ncols = 5, xmin = 0, xmax = 5, ymin = 0, ymax = 1,
                   crs = "EPSG:32632",
                   vals = c(0.5, 0.7, 1.0, 1.5, NA) * nc2)
  d <- diagnose_N_status(N, 2, "wheat", is_percent = TRUE)
  expect_s4_class(d$class, "SpatRaster")
  expect_equal(names(d$class), "NNI_class")
  expect_equal(terra::values(d$class, mat = FALSE), c(1, 1, 2, 3, NA))
  expect_equal(d$labels, c("deficient", "optimal", "excessive"))
  expect_equal(unlist(d$summary$counts),
               c(deficient = 2L, optimal = 1L, excessive = 1L))
  expect_equal(unlist(d$summary$fractions),
               c(deficient = 0.5, optimal = 0.25, excessive = 0.25))
})
