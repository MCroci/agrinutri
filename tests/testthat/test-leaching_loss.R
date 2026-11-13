test_that("leaching_loss matches Fert_Office v1.26 rainfall logic (id_rag = 2, Slow, b1 = 39)", {
  skip_if_not_installed("agrinutri")

  r <- leaching_loss(
    winter_rain = 100, start_spring_rain = 0,
    oxygen_availability = "Slow", id_rag = 2, b1 = 39
  )
  expect_equal(r$C1, 0)
  expect_equal(r$C2, 0)

  r <- leaching_loss(
    winter_rain = 150, start_spring_rain = 0,
    oxygen_availability = "Slow", id_rag = 2, b1 = 39
  )
  expect_equal(r$C1, 0)
  expect_equal(r$C2, 0)

  r <- leaching_loss(
    winter_rain = 200, start_spring_rain = 0,
    oxygen_availability = "Slow", id_rag = 2, b1 = 39
  )
  expect_equal(r$C1, 19.5)
  expect_equal(r$C2, 0)

  # Above 250 mm the whole N pronto is lost in autumn-winter, and the excess
  # over 250 mm also counts at the end of winter (C&D!C32): 30 mm -> 3 kg
  r <- leaching_loss(
    winter_rain = 280, start_spring_rain = 0,
    oxygen_availability = "Slow", id_rag = 2, b1 = 39
  )
  expect_equal(r$C1, 39)
  expect_equal(r$C2, 3)
})

test_that("late rain loses the residual N pronto plus 1 kg per 10 mm (C&D!C24, C32)", {
  skip_if_not_installed("agrinutri")
  b <- 29.16
  r <- leaching_loss(220, 80, "Normal", 3, b)
  expect_equal(r$C1, b * 0.70)
  # winter + February = 300 mm: 50 mm over 250 -> residual pool + 5 kg
  expect_equal(r$C2, b - b * 0.70 + 5)
  # No February loss while winter + February <= 250 mm
  r <- leaching_loss(200, 40, "Normal", 3, b)
  expect_equal(r$C2, 0)
})

test_that("perennial crops lose a fixed 30 kg pool and phase rules apply", {
  skip_if_not_installed("agrinutri")
  r <- leaching_loss(200, 0, b1 = 0, perennial = TRUE)
  expect_equal(r$C1, 15)
  r <- leaching_loss(200, 0, b1 = 40, autumn_loss = FALSE)
  expect_equal(r$C1, 0)
})

test_that("N_balance reproduces Fert_Office Bilancio dose for Cerzoo-style durum scenario", {
  skip_if_not_installed("agrinutri")

  out <- N_balance(
    expected_yield_tons_ha = 6,
    crop                   = "Durum wheat (whole plant)",
    ccp                    = "Spring-summer crop 100-130 days",
    sand = 15.5, clay = 18.5,
    Ntot = 1.5, SOM = 2.0, CN = 7.73,
    oxygen_availability    = "Slow",
    winter_rain = 150, start_spring_rain = 0,
    prev_crop   = "Winter cereals straw removal",
    source = "Cattle slurry", fertorg_frequency = "every year",
    location    = "Isolated plain",
    forg_quantity = 0,
    organic_previous_year_N = 0,
    E_to_D = TRUE
  )
  N <- out$A - out$B + out$C1 + out$C2 + out$D - out$E - out$F - out$Forg - out$G
  expect_equal(round(as.numeric(N), 3), 142.246)
})

test_that("invalid oxygen_availability errors", {
  skip_if_not_installed("agrinutri")
  expect_error(
    leaching_loss(160, 0, oxygen_availability = "not_a_real_class", id_rag = 2, b1 = 30),
    "oxygen_availability"
  )
})
