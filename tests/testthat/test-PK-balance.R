# Benchmark tests for P and K balance against Fert_Office v1.26
# Scenario (grano duro pianta intera, 6 t/ha, suolo FL medio impasto):
#   Olsen P = 15 ppm P2O5  -> classe "bassa" (scarso) -> strategia Arricchimento
#   Arricchimento B1 = (22.9 - 15) * 3900/1000 * 1.6 = 49.296 kg P2O5/ha
#   Asportazione A (P2O5) = 6 * 10.6 = 63.6 kg P2O5/ha
#   P2O5 necessario = 63.6 + 49.3 = 112.9 kg/ha (foglio Bilancio)
#
#   K2O input: 150 ppm, classe "media" -> Mantenimento
#   Asportazione A (K2O) = 6 * 19.9 = 119.4 kg K2O/ha
#   Clay 18.5% -> H = 20 kg K2O/ha
#   K2O necessario = 119.4 + 20 = 139.4 kg/ha (foglio Bilancio)

library(testthat)
context("DPI 2026 P & K balance benchmark")

test_that("resolve_crop accepts Italian or English crop names", {
  skip_if_not_installed("NFert")
  # Since NFert 0.12.0 the reference tables are English-canonical.
  # `resolve_crop()` returns the English name regardless of input.
  expect_equal(resolve_crop("Durum wheat (whole plant)"),
               "Durum wheat (whole plant)")
  expect_equal(resolve_crop("Grano duro (pianta intera)"),
               "Durum wheat (whole plant)")
  expect_equal(resolve_crop("durum wheat (whole plant)"),
               "Durum wheat (whole plant)")
})

test_that("calc_crop_N_demand and P_balance accept English crop names", {
  skip_if_not_installed("NFert")
  d_it <- calc_crop_N_demand(6, "Grano duro (pianta intera)")
  d_en <- calc_crop_N_demand(6, "Durum wheat (whole plant)")
  expect_equal(d_it$N_requirement, d_en$N_requirement)

  p_it <- P_balance(6, "Grano duro (pianta intera)",
                    olsen_value = 15, olsen_unit = "P2O5",
                    clay = 18.5, sand = 15.5)
  p_en <- P_balance(6, "Durum wheat (whole plant)",
                    olsen_value = 15, olsen_unit = "P2O5",
                    clay = 18.5, sand = 15.5)
  expect_equal(p_it$P2O5_required, p_en$P2O5_required)
})

test_that("normalise_soil_group accepts all naming conventions", {
  skip_if_not_installed("NFert")
  # Italian plural (canonical)
  expect_equal(normalise_soil_group("Sabbiosi")$id_rag, 1L)
  expect_equal(normalise_soil_group("Medio impasto")$id_rag, 2L)
  expect_equal(normalise_soil_group("Argillosi e limosi")$id_rag, 3L)
  # Italian singular (Ragg_Tes)
  expect_equal(normalise_soil_group("Sabbioso")$id_rag, 1L)
  expect_equal(normalise_soil_group("Franco")$id_rag, 2L)
  expect_equal(normalise_soil_group("Argilloso")$id_rag, 3L)
  # English (legacy NFert 0.1.0)
  expect_equal(normalise_soil_group("Sandy textures")$id_rag, 1L)
  expect_equal(normalise_soil_group("Loamy textures")$id_rag, 2L)
  expect_equal(normalise_soil_group("Clay textures")$id_rag, 3L)
  # Case-insensitive
  expect_equal(normalise_soil_group("medio impasto")$id_rag, 2L)
  # Canonical English label (used for joins)
  expect_equal(normalise_soil_group("Loamy textures")$en, "Loamy textures")
  expect_equal(normalise_soil_group("Franco")$en, "Loamy textures")
  # Unknown -> error
  expect_error(normalise_soil_group("foo"))
})

test_that("P_balance and K_balance work with any soil_group convention", {
  skip_if_not_installed("NFert")
  scenarios <- list(
    "Sabbiosi", "Sabbioso", "Sandy textures",
    "Medio impasto", "Franco", "Loamy textures"
  )
  for (sg in scenarios) {
    p <- P_balance(expected_yield_tons_ha = 6,
                   crop = "Grano duro (pianta intera)",
                   olsen_value = 15, olsen_unit = "P2O5",
                   soil_group = sg)
    expect_true(is.finite(p$P2O5_required), info = sg)
    k <- K_balance(expected_yield_tons_ha = 6,
                   crop = "Grano duro (pianta intera)",
                   k_value = 150, k_unit = "K2O",
                   soil_group = sg, clay = 18.5)
    expect_true(is.finite(k$K2O_required), info = sg)
  }
})

test_that("classify_P_olsen returns correct classes", {
  skip_if_not_installed("NFert")
  c1 <- classify_P_olsen(value = 15, unit = "P2O5")
  expect_equal(c1$ID_Gri_P, 2)
  expect_equal(c1$strategy, "Arricchimento")

  c2 <- classify_P_olsen(value = 30, unit = "P2O5")
  expect_true(c2$ID_Gri_P %in% 3:4)
  expect_equal(c2$strategy, "Mantenimento")

  c3 <- classify_P_olsen(value = 80, unit = "P2O5")
  expect_equal(c3$ID_Gri_P, 5)
  expect_equal(c3$strategy, "Riduzione")
})

test_that("P_balance reproduces grano duro scenario (112.9 kg P2O5/ha)", {
  skip_if_not_installed("NFert")
  b <- P_balance(expected_yield_tons_ha = 6,
                 crop = "Grano duro (pianta intera)",
                 olsen_value = 15, olsen_unit = "P2O5",
                 clay = 18.5, sand = 15.5)
  # Fert_Office v1.26 Bilancio!I15, I20, I33: A 63.6 + B1 49.296 = 112.896
  expect_equal(b$A, 63.6, tolerance = 1e-6)
  expect_equal(b$B1, 49.296047736, tolerance = 1e-6)
  expect_equal(b$P2O5_required, 112.896047736, tolerance = 1e-6)
})

test_that("classify_K returns correct classes by soil group", {
  skip_if_not_installed("NFert")
  c1 <- classify_K(value = 150, unit = "K2O", soil_group = "Medio impasto")
  expect_equal(c1$ID_Gri_K, 3)
  expect_equal(c1$strategy, "Mantenimento")

  c2 <- classify_K(value = 60, unit = "K2O", soil_group = "Medio impasto")
  expect_true(c2$ID_Gri_K %in% 1:2)
  expect_equal(c2$strategy, "Arricchimento")
})

test_that("K_leaching_by_clay step function", {
  skip_if_not_installed("NFert")
  expect_equal(K_leaching_by_clay(2), 60)
  expect_equal(K_leaching_by_clay(10), 30)
  expect_equal(K_leaching_by_clay(18.5), 20)
  expect_equal(K_leaching_by_clay(30), 10)
})

test_that("K_balance reproduces grano duro scenario (139.4 kg K2O/ha)", {
  skip_if_not_installed("NFert")
  b <- K_balance(expected_yield_tons_ha = 6,
                 crop = "Grano duro (pianta intera)",
                 k_value = 150, k_unit = "K2O",
                 clay = 18.5, sand = 15.5)
  # Fert_Office v1.26 Bilancio!J15, J16, J33
  expect_equal(b$A, 119.4, tolerance = 1e-6)
  expect_equal(b$H, 20)
  expect_equal(b$K2O_required, 139.4, tolerance = 1e-6)
})

test_that("plan_distribution aggregates organic + mineral and checks excess", {
  skip_if_not_installed("NFert")
  out <- plan_distribution(
    soil_group = "Medio impasto",
    n_balance = 142, p_balance = 113, k_balance = 140,
    organic_rows = list(list(fertilizer = "letame bovino",
                             quantity_t_ha = 20, year = 2025,
                             modality_epoch = 1, level = "media")),
    mineral_rows = list(list(fertilizer = "UREA AGRICOLA PRIL.46%",
                             quantity_q_ha = 3,
                             modality_epoch = 11)),
    zvn = TRUE
  )
  expect_true(nrow(out$rows) >= 1)
  expect_true(out$totals["N_useful"] > 0)
  # Mineral urea: 3 q * 46% = 138 kg N/ha all useful
  expect_true(out$rows$N_useful[out$rows$source == "mineral"][1] > 130)
})

test_that("end-of-cycle soil P estimation returns consistent ppm", {
  skip_if_not_installed("NFert")
  end <- estimate_soil_P_end_of_cycle(
    P2O5_start_ppm = 15, P2O5_applied = 113,
    P2O5_removed = 63.6, soil_group = "Medio impasto")
  # delta positivo (apporto > asportazione) -> dotazione sale
  expect_true(is.finite(end))

  end_k <- estimate_soil_K_end_of_cycle(
    K2O_start_ppm = 150, K2O_applied = 140,
    K2O_removed = 119.4, clay_pct = 18.5,
    soil_group = "Medio impasto")
  expect_true(is.numeric(end_k))
})

test_that("scheda_PK returns base doses for grano duro", {
  skip_if_not_installed("NFert")
  r <- scheda_PK(crop = "Grano duro (pianta intera)",
                 soil_P_class = "normal", soil_K_class = "normal")
  expect_true(!is.na(r$dose_base_P2O5))
  expect_true(!is.na(r$dose_base_K2O))
  expect_equal(r$dose_final_P2O5, r$dose_base_P2O5)  # no adjustments
})

test_that("soil chemistry classifiers work", {
  skip_if_not_installed("NFert")
  expect_equal(classify_pH(8.3)$class, "alkaline")
  expect_equal(classify_carbonate_tot(15)$class, "Moderately calcareous")
  expect_equal(classify_carbonate_att(6.8)$class, "High")
  expect_equal(classify_CEC(18)$class, "media")
  expect_equal(max_SO_input("Normal"), 11)
  expect_equal(classify_SOM(SOM = 2, soil_group = "Medio impasto")$class, "Normal")
})