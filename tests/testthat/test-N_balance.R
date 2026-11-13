test_that("N_balance returns correct structure", {
  result <- N_balance(
    expected_yield_tons_ha = 15,
    crop = "Mais trinciato (classe 700)",
    ccp = "Spring-summer crop 100–130 days",
    sand = 50,
    clay = 35,
    Ntot = 1.2,
    SOM = 1.2,
    CN = 9.5,
    oxygen_availability = "Normal",
    winter_rain = 160,
    start_spring_rain = 40,
    prev_crop = "Winter cereals straw removal",
    source = "Cattle slurry",
    fertorg_frequency = "every year",
    location = "Plain adjacent to urbanized areas",
    forg_quantity = 100
  )
  
  expect_s3_class(result, "data.frame")
  expect_named(result, c("A", "B", "b1", "b2", "C1", "C2", "D", "E", "F", "Forg", "G",
                         "G_deposition", "G_fixation", "no_till_reduction",
                         "C_tempo", "N_pct", "N_limit", "surplus_pluviometrico"))
  num_cols <- setdiff(names(result), "surplus_pluviometrico")
  expect_true(all(vapply(num_cols, function(nm) is.numeric(result[[nm]][1]), logical(1))))
  expect_equal(nrow(result), 1)
})

test_that("N_balance validates input correctly", {
  expect_error(
    N_balance(expected_yield_tons_ha = -5),
    "Expected yield must be a positive numeric value"
  )
  
  expect_error(
    N_balance(sand = 60, clay = 50),
    "The sum of sand and clay percentages cannot exceed 100%"
  )
  
  expect_error(
    N_balance(sand = -5),
    "Sand percentage must be a numeric value between 0 and 100"
  )
  
  expect_error(
    N_balance(clay = 150),
    "Clay percentage must be a numeric value between 0 and 100"
  )
  
  expect_error(
    N_balance(Ntot = -1),
    "Total nitrogen \\(Ntot\\) must be a non-negative numeric value"
  )
  
  expect_error(
    N_balance(SOM = -1),
    "Soil organic matter \\(SOM\\) must be a non-negative numeric value"
  )
  
  expect_error(
    N_balance(CN = 0),
    "Carbon to nitrogen ratio \\(CN\\) must be a positive numeric value"
  )
})

test_that("N_balance calculates all components", {
  result <- N_balance(
    expected_yield_tons_ha = 10,
    crop = "Grano tenero FF (granella)",
    sand = 30,
    clay = 25
  )
  
  # All components should be numeric and non-NA
  expect_true(all(!is.na(result[1, ])))
  expect_true(all(result$A > 0))
  expect_true(all(result$B >= 0))
})

test_that("N_balance uses DPI organic path by default (Forg scales with dose)", {
  low <- N_balance(
    expected_yield_tons_ha = 60,
    crop = "Silage maize (class 700)",
    ccp = "Spring-summer crop 100-130 days",
    sand = 16.8,
    clay = 37,
    Ntot = 1.2,
    SOM = 1.7,
    CN = 8.84,
    oxygen_availability = "Normal",
    winter_rain = 150,
    start_spring_rain = 0,
    prev_crop = "Maize stalks buried",
    source = "Cattle slurry",
    fertorg_frequency = "every year",
    location = "Isolated plain",
    forg_quantity = 1,
    organic_previous_year_N = 0,
    E_to_D = TRUE
  )
  hi <- N_balance(
    expected_yield_tons_ha = 60,
    crop = "Silage maize (class 700)",
    ccp = "Spring-summer crop 100-130 days",
    sand = 16.8,
    clay = 37,
    Ntot = 1.2,
    SOM = 1.7,
    CN = 8.84,
    oxygen_availability = "Normal",
    winter_rain = 150,
    start_spring_rain = 0,
    prev_crop = "Maize stalks buried",
    source = "Cattle slurry",
    fertorg_frequency = "every year",
    location = "Isolated plain",
    forg_quantity = 154,
    organic_previous_year_N = 0,
    E_to_D = TRUE
  )
  expect_true(hi$Forg > 50)
  expect_true(hi$Forg > low$Forg * 80)
})
