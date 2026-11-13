# organic_previous_years_N(): DPI 2026 sec. 3.1.6 recovery coefficients (term F)

test_that("organic_previous_years_N reproduces the roxygen examples", {
  expect_equal(organic_previous_years_N(100, "Cattle slurry", "every year"), 30)
  expect_equal(organic_previous_years_N(80, "Composted manure", "every two years"), 24)
})

test_that("organic_previous_years_N uses the full DPI recovery table", {
  # Ammendante 50/30/20/20; liquame bovino 30/15/10/0; suino/pollina 15/10/5/0
  freqs <- c("every year", "every two years", "every three years", "occasional")
  expected <- list(
    "Composted mixed amendment" = c(50, 30, 20, 20),
    "Dairy cattle slurry"       = c(30, 15, 10, 0),
    "Pig slurry"                = c(15, 10, 5, 0)
  )
  for (src in names(expected)) {
    got <- vapply(freqs, function(f) organic_previous_years_N(100, src, f), numeric(1))
    expect_equal(unname(got), expected[[src]], info = src)
  }
})

test_that("organic_previous_years_N maps Italian sources and frequency aliases", {
  expect_equal(organic_previous_years_N(100, "letame maturo", "ogni anno"), 50)
  expect_equal(organic_previous_years_N(100, "Liquame bovino", "ogni due anni"), 15)
  expect_equal(organic_previous_years_N(100, "Pollina", "every 3 years"), 5)
  expect_equal(organic_previous_years_N(100, "liquami suini", "saltuaria"), 0)
  expect_equal(organic_previous_years_N(100, "Poultry litter", "annual"), 15)
  expect_equal(organic_previous_years_N(100, "Ammendante", "every 2 years"), 30)
  expect_equal(organic_previous_years_N(100, "palabile", "ogni tre anni"), 20)
  expect_equal(organic_previous_years_N(100, "compost", "saltuario"), 20)
})

test_that("organic_previous_years_N defaults unknown source/frequency to cattle slurry / every year", {
  expect_equal(organic_previous_years_N(100, "Mystery source", "every year"), 30)
  expect_equal(organic_previous_years_N(100, "Pig slurry", "whenever"), 15)
})

test_that("organic_previous_years_N returns 0 for missing or non-positive N", {
  expect_equal(organic_previous_years_N(0, "Cattle slurry", "every year"), 0)
  expect_equal(organic_previous_years_N(-5, "Cattle slurry", "every year"), 0)
  expect_equal(organic_previous_years_N(NA, "Cattle slurry", "every year"), 0)
  expect_equal(organic_previous_years_N(NULL, "Cattle slurry", "every year"), 0)
})

test_that(".organic_recovery_table is a complete 4 x 4 grid in [0, 1]", {
  tab <- NFert:::.organic_recovery_table()
  expect_equal(nrow(tab), 16L)
  expect_equal(nrow(unique(tab[, c("organic_type", "frequency")])), 16L)
  expect_true(all(tab$recovery >= 0 & tab$recovery <= 1))
  expect_true(all(tab$recovery[tab$organic_type == "none"] == 0))
  # recovery never increases as application frequency decreases
  for (ty in unique(tab$organic_type))
    expect_true(all(diff(tab$recovery[tab$organic_type == ty]) <= 0), info = ty)
})
