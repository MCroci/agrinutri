# nfert_to_quefts_soil / _crop / _biom and nfert_crop_pars_quefts()

test_that("nfert_to_quefts_soil maps supplies and recoveries verbatim", {
  s <- nfert_to_quefts_soil(45, P_supply = 12, K_supply = 70,
                            N_recovery = 0.6, P_recovery = 0.12, K_recovery = 0.4)
  expect_equal(s$N_base_supply, 45)
  expect_equal(s$P_base_supply, 12)
  expect_equal(s$K_base_supply, 70)
  expect_equal(c(s$N_recovery, s$P_recovery, s$K_recovery), c(0.6, 0.12, 0.4))
  expect_equal(dim(s$UptakeAdjust), c(7L, 2L))
  expect_equal(s$UptakeAdjust[, 1], c(0, 40, 80, 120, 240, 360, 1000))
  expect_equal(s$UptakeAdjust[, 2], c(0, 0.4, 0.7, 1.0, 1.6, 2.0, 2.0))
  d <- nfert_to_quefts_soil("30")                  # coerced to numeric
  expect_identical(d$N_base_supply, 30)
  expect_equal(c(d$P_base_supply, d$K_base_supply), c(10, 60))
  expect_equal(c(d$N_recovery, d$P_recovery, d$K_recovery), c(0.55, 0.10, 0.50))
})

test_that("nfert_to_quefts_crop returns the bundled CSV row (exact and partial match)", {
  tab <- utils::read.csv(system.file("extdata", "quefts_crop_pars_IT.csv",
                                     package = "NFert"),
                         stringsAsFactors = FALSE, check.names = FALSE)
  row <- tab[tab$crop == "Orzo (granella)", ]
  cp <- nfert_to_quefts_crop("  orzo (GRANELLA) ")  # case / whitespace insensitive
  expect_named(cp, c("NminVeg", "NmaxVeg", "NminStore", "NmaxStore",
                     "PminVeg", "PmaxVeg", "PminStore", "PmaxStore",
                     "KminVeg", "KmaxVeg", "KminStore", "KmaxStore",
                     "Yzero", "Nfix", "SeasonLength"))
  expect_equal(cp$Yzero, row$Yzero)
  expect_equal(cp$NmaxStore, row$NmaxStore)
  expect_equal(cp$SeasonLength, row$SeasonLength)

  # Partial (substring) match: table label contained in the query
  part <- nfert_to_quefts_crop("Riso (granella) - varieta Carnaroli")
  expect_equal(part$Yzero, tab$Yzero[tab$crop == "Riso (granella)"])
})

test_that("nfert_to_quefts_crop errors for unknown crops and missing files, and reads custom CSVs", {
  expect_error(nfert_to_quefts_crop("Crop that does not exist"),
               "not found in QUEFTS calibration table")
  expect_error(nfert_to_quefts_crop("Orzo", crop_pars_path = file.path(tempdir(), "nope.csv")),
               "Crop parameters file not found")

  src <- utils::read.csv(system.file("extdata", "quefts_crop_pars_IT.csv",
                                     package = "NFert"),
                         stringsAsFactors = FALSE, check.names = FALSE)
  custom <- src[1, ]
  custom$crop <- "My local wheat"
  custom$Yzero <- 123
  p <- tempfile(fileext = ".csv")
  on.exit(unlink(p), add = TRUE)
  utils::write.csv(custom, p, row.names = FALSE)
  expect_equal(nfert_to_quefts_crop("My local wheat", crop_pars_path = p)$Yzero, 123)
})

test_that("nfert_to_quefts_biom partitions yield by clamped NNI", {
  cp <- list(SeasonLength = 150)
  b <- nfert_to_quefts_biom(6, 0.8, cp)
  expect_equal(b$store_att, 6000 * 0.8)
  expect_equal(b$leaf_att, 4800 * 0.42)
  expect_equal(b$stem_att, 4800 * 0.42)
  expect_equal(b$SeasonLength, 150)

  expect_equal(nfert_to_quefts_biom(6, 2.0, cp)$store_att, 6000 * 1.10)
  expect_equal(nfert_to_quefts_biom(6, 0.1, cp)$store_att, 6000 * 0.30)
  expect_equal(nfert_to_quefts_biom(5, 1, cp, leaf_to_store_ratio = 0.5)$leaf_att, 2500)

  v <- nfert_to_quefts_biom(6, c(0.5, 1.0, 1.5), cp)
  expect_length(v, 3L)
  expect_equal(vapply(v, `[[`, numeric(1), "store_att"), c(3000, 6000, 6600))
  expect_true(all(vapply(v, `[[`, numeric(1), "SeasonLength") == 150))
})

test_that("nfert_crop_pars_quefts passes lists through and looks up labels", {
  lst <- list(Yzero = 1, SeasonLength = 100, foo = "bar")
  expect_identical(nfert_crop_pars_quefts(lst), lst)
  expect_identical(nfert_crop_pars_quefts("Grano duro (granella)"),
                   nfert_to_quefts_crop("Grano duro (granella)"))
})

test_that("nfert_crop_pars_quefts falls back to Rquefts::quefts_crop with a warning", {
  skip_if_not_installed("Rquefts")
  expect_warning(cp <- nfert_crop_pars_quefts("Soia (granella)"),
                 "using Rquefts::quefts_crop\\(\\) fallback")
  expect_identical(cp, Rquefts::quefts_crop("Soyabean"))
})

test_that(".nfert_crop_fallback_quefts maps Italian/English labels to Rquefts crops", {
  skip_if_not_installed("Rquefts")
  fb <- NFert:::.nfert_crop_fallback_quefts
  q <- Rquefts::quefts_crop
  expect_identical(fb("Orzo da seme (granella)"), q("Barley"))
  expect_identical(fb("Frumento tenero"),         q("Wheat"))
  expect_identical(fb("Mais dolce (spighe)"),     q("Maize"))
  expect_identical(fb("Rice"),                    q("Rice"))
  expect_identical(fb("Soybean (seed)"),          q("Soyabean"))
  expect_identical(fb("Patata"),                  q("Potato"))
  expect_identical(fb("Colza"),                   q("Wheat"))   # default
})
