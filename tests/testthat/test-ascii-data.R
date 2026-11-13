# Bundled data must be ASCII (CRAN), and accent-insensitive matching must
# keep Italian/accented user input resolving to the canonical row.

test_that("no bundled dataset contains non-ASCII characters", {
  # Works both on the installed package (lazy-load database) and under
  # load_all(): list the datasets from the package metadata and fetch each one.
  items <- utils::data(package = "agrinutri")$results[, "Item"]
  items <- sub(" .*$", "", items)          # drop "(alias)" suffixes
  expect_gt(length(items), 10L)
  bad <- character()
  for (nm in items) {
    obj <- tryCatch(agrinutri_data_get(nm), error = function(e) NULL)
    if (is.null(obj)) next
    cols <- if (is.data.frame(obj)) obj else list(obj)
    for (col in cols) {
      x <- if (is.factor(col)) levels(col) else col
      if (is.character(x) && any(grepl("[^ -~]", x, useBytes = TRUE), na.rm = TRUE))
        bad <- c(bad, nm)
    }
  }
  expect_identical(unique(bad), character())
})

test_that("accent-insensitive matching keeps accented input resolving", {
  fold <- agrinutri:::.agrinutri_ascii_fold
  # Build the accented inputs from code points so this test file stays ASCII.
  deg  <- intToUtf8(0xB0L)    # degree sign
  ugr  <- intToUtf8(0xF9L)    # u-grave
  dash <- intToUtf8(0x2013L)  # en-dash
  expect_equal(fold(paste0("1", deg, " taglio")), "1o taglio")
  expect_equal(fold(paste0("pi", ugr, " / 70", dash, "100")), "piu / 70-100")
  # resolve_crop still maps a legacy Italian crop name to the English canonical
  expect_equal(resolve_crop("Mais trinciato classe 700"), "Silage maize (class 700)")
})
