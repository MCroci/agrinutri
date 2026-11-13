# Benchmark tests against Fert_Office v1.26 (Bilancio sheet, Grano duro pianta intera)
# Scenario taken from the "Inserimento" sample:
#   Sabbia 15.5, Argilla 18.5, Limo 66   -> FL (Medio impasto)
#   Ntot 1.5 g/kg, SO 2%, CN 7.73 (basso)
#   Calcare tot 15, calcare att 6.8, pH 8.3
#   Pioggia 1/10-31/1 = 150 mm, febbraio = 0 mm
#   Precessione: Maize stalks removed (E = -10)
#   Grano duro (pianta intera), resa 6 t/ha, fase primaverile-estiva 100-130 gg
#   Disponibilita ossigeno: Imperfetta (NFert "Slow") -> fc_D = 0.40
#   Apporti naturali: pianura isolata -> G = 15 kg/ha * C_tempo 0.67 = 10.05
#
# Expected (from foglio Bilancio):
#   A = 186.6, B = 73.84, C = 0, D = 39.536, E = 0 (dopo fold to D), G = 10.05
#   Dose ammessa = 142.246 kg N/ha  (Bilancio!B33)
#
# Expected (from foglio Scheda_N, stesso scenario con flags: ristoppio+compattato):
#   dose base = 160, incrementi = 30 + 10 = 40, dose ricalcolata = 200, MAS cap = 200
#   dose finale = 200 kg N/ha

library(testthat)

context("DPI 2026 Fert_Office v1.26 benchmark")

test_that("N_balance (grano duro) reproduces Fert_Office Bilancio", {
  skip_if_not_installed("NFert")

  # Inputs exactly as in the Fert_Office v1.26 "Inserimento" sample:
  # oxygen availability "Imperfetta" (ID_Dre 1 = "Slow") and location
  # "Pianura isolata" (15 kg N/ha/yr).
  bal <- N_balance(
    expected_yield_tons_ha = 6,
    crop = "Grano duro (pianta intera)",
    ccp  = "Spring-summer crop 100-130 days",
    sand = 15.5, clay = 18.5,
    Ntot = 1.5, SOM = 2, CN = 7.733952049497294,
    oxygen_availability = "Slow",
    winter_rain = 150, start_spring_rain = 0,
    prev_crop = "Maize stalks removed",
    source = "None",
    fertorg_frequency = "every year",
    location = "Isolated plain",
    forg_quantity = 0,
    soil_seeding = "traditional",
    greenhouse = FALSE,
    E_to_D = TRUE
  )

  # Term by term against Bilancio!H15:H28
  expect_equal(bal$A,  186.6,  tolerance = 1e-8)   # 31.1 kg N/t x 6 t/ha
  expect_equal(bal$C1 + bal$C2, 0)                 # Bilancio!H16
  expect_equal(bal$D,  39.536, tolerance = 1e-8)   # 0.40 x B + |E| (C&D!G23)
  expect_equal(bal$B,  73.84,  tolerance = 1e-8)   # Bilancio!H25
  expect_equal(bal$E,  0)                          # E = -10 folded into D
  expect_equal(bal$F,  0)
  expect_equal(bal$G,  10.05,  tolerance = 1e-8)   # 15 x C_tempo 0.67
  # Apporto ammesso col metodo Bilancio (Bilancio!H33)
  expect_equal(calculate_N_fertilization(bal), 142.246, tolerance = 1e-8)
})

test_that("scheda_N reproduces Scheda_N grano duro (200 kg/ha)", {
  skip_if_not_installed("NFert")

  res <- scheda_N(
    crop = "Grano duro (pianta intera)",
    increments = c(straw_burial = 30, compacted_no_till = 10)
  )
  expect_equal(res$dose_base,       160)
  expect_equal(res$total_increment,  40)
  expect_equal(res$total_decrement,   0)
  expect_equal(res$dose_recalculated, 200)
  expect_equal(res$dose_final,        200)
  expect_false(res$mas_exceeded)
})

test_that("scheda_N cap at MAS when decrements < increments overshoot dose_max", {
  skip_if_not_installed("NFert")
  res <- scheda_N(
    crop = "Grano duro (pianta intera)",
    increments = c(straw_burial = 100, compacted_no_till = 100)
  )
  expect_true(res$mas_exceeded)
  expect_equal(res$dose_final, res$max_N_dose)
})

test_that("no-till soil_seeding reduces B by 10 kg/ha (DPI Allegato 2)", {
  skip_if_not_installed("NFert")
  b_trad <- soil_fertility(Ntot = 1.5, SOM = 2, soil.group = "Loamy textures",
                           CN = 8, ccp = "Spring-summer crop 100-130 days",
                           soil_seeding = "traditional")
  b_not  <- soil_fertility(Ntot = 1.5, SOM = 2, soil.group = "Loamy textures",
                           CN = 8, ccp = "Spring-summer crop 100-130 days",
                           soil_seeding = "no-till")
  expect_equal(b_trad$B - b_not$B, 10)
  expect_equal(b_not$no_till_reduction, 10)
  expect_equal(b_trad$b2, b_not$b2)
  # not for perennial crops in production, nor for crops excluded by the DPI
  b_per <- soil_fertility(Ntot = 1.5, SOM = 2, soil.group = "Loamy textures",
                          CN = 8, ccp = "full production", soil_seeding = "no-till")
  expect_equal(b_per$no_till_reduction, 0)
})

test_that("soil_fertility follows Fert_Office caps and the perennial rule", {
  skip_if_not_installed("NFert")
  ccp <- "Spring-summer crop 100-130 days"          # C_tempo 0.67
  hi <- soil_fertility(Ntot = 3, SOM = 5, soil.group = "Loamy textures",
                       CN = 10, ccp = ccp)
  cap <- soil_fertility(Ntot = 2.1, SOM = 3, soil.group = "Loamy textures",
                        CN = 10, ccp = ccp)
  expect_equal(hi$B, cap$B)                          # Ntot <= 2.1, SOM <= 3
  expect_equal(cap$b1, 2.1 * 26)
  expect_equal(cap$b2, 3 * 24.05 * 0.67)
  per <- soil_fertility(Ntot = 1.5, SOM = 2, soil.group = "Clay textures",
                        CN = 13, ccp = "full production")   # C_tempo 1
  expect_equal(per$b1, 0)                             # B = mineralised N only
  expect_equal(per$b2, 2 * 6)
})

test_that("greenhouse adds 2 kg/ha to D", {
  skip_if_not_installed("NFert")
  D1 <- calc_N_immobilization_loss(B = 50, oxygen_availability = "Normal",
                                   id_rag = 2, greenhouse = FALSE)
  D2 <- calc_N_immobilization_loss(B = 50, oxygen_availability = "Normal",
                                   id_rag = 2, greenhouse = TRUE)
  expect_equal(D2 - D1, 2)
})

test_that("negative E is folded into D", {
  skip_if_not_installed("NFert")
  D_no_e <- calc_N_immobilization_loss(B = 60, oxygen_availability = "Normal",
                                       id_rag = 2, E_residual = 0)
  D_e    <- calc_N_immobilization_loss(B = 60, oxygen_availability = "Normal",
                                       id_rag = 2, E_residual = -40)
  expect_equal(D_e - D_no_e, 40)
})

test_that("surplus_pluviometrico flag is TRUE when winter + feb >= 300 mm", {
  skip_if_not_installed("NFert")
  r1 <- leaching_loss(winter_rain = 250, start_spring_rain = 60,
                      oxygen_availability = "Normal", id_rag = 2, b1 = 30)
  r2 <- leaching_loss(winter_rain = 150, start_spring_rain = 30,
                      oxygen_availability = "Normal", id_rag = 2, b1 = 30)
  expect_true(r1$surplus_pluviometrico)
  expect_false(r2$surplus_pluviometrico)
})
