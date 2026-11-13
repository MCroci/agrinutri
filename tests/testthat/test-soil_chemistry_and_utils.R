# classify_pH / carbonate / CEC / ratio helpers, soil-group utilities,
# calculate_N_fertilization(), nitrogen_from_previous_crop_residues() and the
# internal data / oxygen helpers.

test_that("classify_pH assigns the 7 DPI classes for interior values", {
  ids <- vapply(c(4.8, 5.7, 6.4, 7.0, 7.8, 8.4, 9.2),
                function(p) classify_pH(p)$ID_pH, integer(1))
  expect_equal(ids, 1:7)
  res <- classify_pH(8.4)
  expect_equal(res$class, "alkaline")
  expect_equal(res$pH, 8.4)
  expect_equal(classify_pH(4.8)$class, "strongly acid")
  expect_error(classify_pH("7"), "single numeric")
  expect_error(classify_pH(c(6, 7)), "single numeric")
  expect_error(classify_pH(NA_real_), "single numeric")
})

test_that("classify_pH thresholds behave like the Fert_Office VLOOKUP", {
  # Fert_Office foglio pH: VLOOKUP on lower thresholds, so a value equal to a
  # threshold falls in the upper class.
  expect_equal(classify_pH(5.9)$class, "acid")
  expect_equal(classify_pH(6.0)$class, "slightly acid")
  expect_equal(classify_pH(6.7)$class, "neutral")
  expect_equal(classify_pH(7.3)$class, "slightly alkaline")
  expect_equal(classify_pH(8.1)$class, "alkaline")
})

test_that("carbonate classifiers use half-open [min, max) intervals", {
  expect_equal(classify_carbonate_tot(0.5)$ID, 1L)
  expect_equal(classify_carbonate_tot(1)$ID, 2L)
  expect_equal(classify_carbonate_tot(15)$class, "Moderately calcareous")
  expect_equal(classify_carbonate_tot(60)$ID, 5L)
  na_tot <- classify_carbonate_tot(150)
  expect_true(is.na(na_tot$ID) && is.na(na_tot$class))
  expect_equal(na_tot$caco3_tot, 150)
  expect_error(classify_carbonate_tot(NA_real_), "single numeric")

  expect_equal(classify_carbonate_att(0.2)$class, "Low")
  expect_equal(classify_carbonate_att(5)$ID, 3L)
  expect_equal(classify_carbonate_att(6.8)$class, "High")
  expect_equal(classify_carbonate_att(7.5)$class, "Very high")
  expect_true(is.na(classify_carbonate_att(-1)$ID))
  expect_error(classify_carbonate_att("a"), "single numeric")
})

test_that("classify_CEC thresholds: <10 bassa, 10-20 media, >20 alta", {
  expect_equal(classify_CEC(9.9)$class, "bassa")
  expect_equal(classify_CEC(10)$class, "media")
  expect_equal(classify_CEC(20)$class, "media")
  expect_equal(classify_CEC(20.1)$class, "alta")
  expect_equal(classify_CEC(18)$csc, 18)
  expect_equal(classify_CEC(NA_real_)$class, "non valorizzato")
  expect_equal(classify_CEC("x")$class, "non valorizzato")
})

test_that("ratio_Mg_K converts ppm to meq and classifies the ratio", {
  r <- ratio_Mg_K(mg_ppm = 121.5, k_ppm = 150)
  expect_equal(r$ratio, (121.5 / 12.15) / (150 / 39.10))
  expect_equal(r$class, "alto")                      # 2.61
  expect_equal(ratio_Mg_K(1, 100)$class, "basso")
  expect_equal(ratio_Mg_K(50, 100)$class, "equilibrato")
  expect_equal(ratio_Mg_K(300, 100)$class, "molto alto")
  z <- ratio_Mg_K(100, 0)
  expect_true(is.na(z$ratio))
  expect_equal(z$class, "non calcolato")
  expect_equal(ratio_Mg_K("100", 50)$class, "non calcolato")
})

test_that("ratio_K_CEC returns the percentage of CEC and its class", {
  r <- ratio_K_CEC(k_meq_per_100g = 0.38, csc_meq = 18)
  expect_equal(r$pct, 100 * 0.38 / 18)
  expect_equal(r$class, "alto")                      # 2.11 %
  expect_equal(ratio_K_CEC(0.01, 20)$class, "basso")
  expect_equal(ratio_K_CEC(0.2, 20)$class, "ottimale")
  expect_equal(ratio_K_CEC(2, 20)$class, "non calcolato")   # >= 5.1 %
  expect_equal(ratio_K_CEC(0.3, 0)$class, "non calcolato")
  expect_true(is.na(ratio_K_CEC("a", 10)$pct))
})

test_that("ratio_K_CEC handles a missing CEC gracefully", {
  expect_equal(ratio_K_CEC(0.3, NA_real_)$class, "non calcolato")
})

test_that("normalise_soil_group accepts all three naming conventions", {
  for (lab in c("Sabbiosi", "sabbioso", "Sandy textures", "S"))
    expect_equal(normalise_soil_group(lab)$id_rag, 1L, info = lab)
  for (lab in c("Medio impasto", "Franco", "LOAMY TEXTURES", " loam "))
    expect_equal(normalise_soil_group(lab)$id_rag, 2L, info = lab)
  for (lab in c("Argillosi e limosi", "Argilloso", "Clay textures", "clayey"))
    expect_equal(normalise_soil_group(lab)$id_rag, 3L, info = lab)
  g <- normalise_soil_group("Franco")
  expect_equal(g[c("it_plural", "it_singular", "en")],
               list(it_plural = "Medio impasto", it_singular = "Franco",
                    en = "Loamy textures"))
  expect_error(normalise_soil_group("Peaty"), "Unrecognised soil group")
  expect_error(normalise_soil_group(1), "single non-NA character")
  expect_error(normalise_soil_group(NA_character_), "single non-NA character")
})

test_that("resolve_id_rag uses the label first, then clay/sand", {
  expect_equal(resolve_id_rag("Argillosi"), 3L)
  expect_equal(resolve_id_rag(clay = 18.5, sand = 15.5),
               as.integer(calc_soil_group_and_id_rag(clay = 18.5, sand = 15.5)$id_rag))
  expect_type(resolve_id_rag(clay = 5, sand = 85), "integer")
  expect_error(resolve_id_rag(clay = 20), "Provide either")
})

test_that(".texture_group_weight_col finds English or Italian weight columns", {
  f <- NFert:::.texture_group_weight_col
  expect_equal(f(30, data.frame(soil_weight_30cm = 1)), "soil_weight_30cm")
  expect_equal(f(40, data.frame(peso_40cm = 1)), "peso_40cm")
  expect_error(f(50, data.frame(peso_40cm = 1)), "No soil weight column for depth 50")
})

.bal_df <- function(...) {
  b <- data.frame(A = 200, B = 60, C1 = 10, C2 = 5, D = 15, E = 20, F = 10,
                  Forg = 30, G = 20)
  utils::modifyList(b, list(...))
}

test_that("calculate_N_fertilization applies A - B + C1 + C2 + D - E - F - Forg - G", {
  expect_equal(calculate_N_fertilization(.bal_df()),
               200 - 60 + 10 + 5 + 15 - 20 - 10 - 30 - 20)   # 90
  b <- .bal_df(); b$F <- NULL                                # F optional
  expect_equal(calculate_N_fertilization(b), 100)
  expect_equal(calculate_N_fertilization(.bal_df(A = 50)), 0) # negative -> 0
  two <- rbind(.bal_df(), .bal_df(A = 1000))                   # first row only
  expect_equal(calculate_N_fertilization(two), 90)
})

test_that("calculate_N_fertilization agrees with N_balance output", {
  bal <- N_balance(
    expected_yield_tons_ha = 6, crop = "Grano duro (granella)",
    ccp = "Spring-summer crop 100-130 days", sand = 15.5, clay = 18.5,
    Ntot = 1.5, SOM = 2, CN = 7.73, oxygen_availability = "Slow",
    winter_rain = 150, start_spring_rain = 0,
    prev_crop = "Winter cereals straw removal", source = "Cattle slurry",
    fertorg_frequency = "every year", location = "Isolated plain",
    forg_quantity = 0
  )
  expect_equal(calculate_N_fertilization(bal),
               max(0, with(bal, A - B + C1 + C2 + D - E - F - Forg - G)))
})

test_that("calculate_N_fertilization zero-fills NA components with a warning", {
  expect_warning(v <- calculate_N_fertilization(.bal_df(B = NA, G = NA)),
                 "set to 0: B, G")
  expect_equal(v, 200 + 10 + 5 + 15 - 20 - 10 - 30)
  # NA F is silently treated as 0
  expect_equal(calculate_N_fertilization(.bal_df(F = NA)), 100)
  expect_warning(calculate_N_fertilization(.bal_df(C1 = NA, C2 = NA, D = NA,
                                                   E = NA, Forg = NA)),
                 "C1, C2, D, E, Forg")
})

test_that("calculate_N_fertilization validates its input", {
  expect_error(calculate_N_fertilization(list(A = 1)), "must be a data frame")
  expect_error(calculate_N_fertilization(data.frame(A = 1, B = 2)),
               "missing required columns: C1, C2, D, E, Forg, G")
  expect_error(calculate_N_fertilization(.bal_df()[0, ]), "empty")
  expect_error(calculate_N_fertilization(.bal_df(A = NA)), "\\(A\\) is NA")
  expect_error(calculate_N_fertilization(.bal_df(), method = "other"), "Unknown method")
})

test_that("nitrogen_from_previous_crop_residues looks up e.table", {
  expect_equal(nitrogen_from_previous_crop_residues("Alfalfa in good conditions"), 80)
  expect_equal(nitrogen_from_previous_crop_residues("Sugar beet"), 30)
  # negative values (straw/stalk immobilisation) are returned as stored; N_balance
  # folds them into D when E_to_D = TRUE
  expect_equal(nitrogen_from_previous_crop_residues("Maize stalks buried"), -40)
  expect_equal(nitrogen_from_previous_crop_residues(), -10)
  custom <- data.frame(previous_crop = "X", N = 12)
  expect_equal(nitrogen_from_previous_crop_residues("X", e.table = custom), 12)
  expect_warning(v <- nitrogen_from_previous_crop_residues("Unknown crop"),
                 "not found")
  expect_true(is.na(v))
})

test_that("nfert_data_get returns namespace objects and errors for unknown names", {
  expect_identical(nfert_data_get("ph.table"), ph.table)
  expect_s3_class(nfert_data_get("e.table"), "data.frame")
  expect_error(suppressWarnings(nfert_data_get("no_such_dataset_xyz")),
               "not found")
})

test_that("nfert_normalize_oxygen maps legacy labels", {
  f <- nfert_normalize_oxygen
  expect_equal(f("Low"), "Slow")
  expect_equal(f("Reduced"), "Slow")
  expect_equal(f("Poor"), "Slow")
  expect_equal(f("High"), "Fast")
  expect_equal(f("Good"), "Fast")
  expect_equal(f(" Normal "), "Normal")
  expect_equal(f("Slow"), "Slow")
  expect_error(f(c("Low", "High")), "length 1")
  expect_error(f("  "), "cannot be empty")
})
