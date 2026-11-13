# agrinutri_en2it() / agrinutri_it2en() translation helpers

test_that("agrinutri_en2it translates every dictionary kind", {
  expect_equal(agrinutri_en2it("Silage maize (class 700)", "crop"), "Mais trinciato classe 700")
  expect_equal(agrinutri_en2it("Maize stalks removed", "prev_crop"), "Mais stocchi asportati")
  expect_equal(agrinutri_en2it("Pig slurry", "source"), "liquami suini")
  expect_equal(agrinutri_en2it("Pre-sowing", "modality_epoch"), "Presemina")
  expect_equal(agrinutri_en2it("Medium efficiency", "level"), "media")
  # default kind is crop
  expect_equal(agrinutri_en2it("Durum wheat"), "Grano duro (granella)")
})

test_that("agrinutri_en2it is case-insensitive, vectorised and passes unknowns through", {
  expect_equal(agrinutri_en2it(c("BARLEY", "rice", "Mais da granella"), "crop"),
               c("Orzo (granella)", "Riso (granella)", "Mais da granella"))
  expect_equal(agrinutri_en2it(c("Dairy cattle slurry", "None"), "source"),
               c("liquami bovini da latte", NA))
  expect_equal(agrinutri_en2it(c(NA, ""), "crop"), c(NA_character_, NA_character_))
  expect_null(agrinutri_en2it(NULL, "crop"))
  expect_error(agrinutri_en2it("x", kind = "colour"))
})

test_that("agrinutri_en2it canonicalises the legacy short soft-wheat aliases", {
  expect_equal(agrinutri_en2it("soft wheat FF", "crop"), "Grano tenero FF (granella)")
  expect_equal(agrinutri_en2it("Soft Wheat FF (whole)", "crop"),
               "Grano tenero FF (pianta intera)")
  # not applied to other kinds
  expect_equal(agrinutri_en2it("soft wheat FF", "source"), "soft wheat FF")
})

test_that("agrinutri_it2en reverses the dictionaries", {
  expect_equal(agrinutri_it2en("Mais trinciato classe 700", "crop"), "Silage maize (class 700)")
  expect_equal(agrinutri_it2en("Medicaio diradato", "prev_crop"), "Alfalfa meadow (thinned)")
  expect_equal(agrinutri_it2en("Presemina", "modality_epoch"), "Pre-sowing")
  expect_equal(agrinutri_it2en("alta", "level"), "High efficiency")
  # duplicated Italian values resolve to the first English alias
  expect_equal(agrinutri_it2en("liquami bovini da carne", "source"), "Beef cattle slurry")
  # exact match only (case-sensitive); unknowns pass through
  expect_equal(agrinutri_it2en("PRESEMINA", "modality_epoch"), "PRESEMINA")
  expect_equal(agrinutri_it2en(c(NA, ""), "level"), c(NA_character_, NA_character_))
  expect_null(agrinutri_it2en(NULL, "crop"))
})

test_that("crop dictionary round-trips EN -> IT -> EN", {
  en <- names(crop_en2it)
  it <- agrinutri_en2it(en, "crop")
  expect_equal(it, unname(crop_en2it))
  # values are unique, so the reverse lookup is a bijection
  expect_false(anyDuplicated(unname(crop_en2it)) > 0)
  expect_equal(agrinutri_it2en(it, "crop"), en)
})

test_that(".make_it2en drops NA entries", {
  rev <- agrinutri:::.make_it2en(source_en2it)
  expect_false("None" %in% rev)
  expect_false(any(is.na(names(rev))))
  expect_equal(unname(rev["letame bovino"]), "Cattle manure")
})
