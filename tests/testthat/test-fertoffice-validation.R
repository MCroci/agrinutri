# Term-by-term validation against the regional reference tool Fert_Office
# v1.26 (DPI Emilia-Romagna 2026). The fixture holds random field scenarios
# (13 crops, 3 texture groups, all drainage classes, precessions, previous
# organic fertilisation and no-till) and the values that Fert_Office computed
# for them, recorded by data-raw/fertoffice_validation.py through Excel.

fixture <- test_path("fixtures", "fertoffice_v1.26_scenarios.csv")

# nfert_vs_fertoffice() is defined in helper-fertoffice.R
nfert_vs_fertoffice_rows <- function() {
  nfert_vs_fertoffice(utils::read.csv(fixture, stringsAsFactors = FALSE))
}

test_that("NFert reproduces Fert_Office v1.26 on random scenarios", {
  skip_if_not(file.exists(fixture), "validation fixture not found")
  r <- nfert_vs_fertoffice_rows()
  expect_gte(nrow(r), 100L)
  tol <- 1e-6
  terms <- c(A = "fo_A", B = "fo_B", C = "fo_C", D = "fo_D", E = "fo_E",
             F = "fo_F", G = "fo_G", N = "fo_N", N_rep = "fo_N_rep",
             P_A = "fo_P_A", P_B1 = "fo_P_B1", P_B2 = "fo_P_B2",
             P2O5 = "fo_P2O5_rep",
             K_A = "fo_K_A", K_H = "fo_K_H", K_F1 = "fo_K_F1", K_F2 = "fo_K_F2",
             K2O = "fo_K2O_rep")
  for (nm in names(terms)) {
    nf <- r[[paste0("nf_", nm)]]
    fo <- r[[terms[[nm]]]]
    bad <- which(abs(nf - fo) > tol)
    expect_length(bad, 0)
    if (length(bad))
      message(nm, ": ", length(bad), " mismatches, e.g. rows ",
              paste(utils::head(bad, 5), collapse = ", "))
  }
})
