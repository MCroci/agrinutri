# Build data/validation_fertoffice.csv for Fig. 2 from the test fixture, the
# current NFert and the old-release doses written by validation_old_release.R.
# Run from the package root:
#   Rscript paper/softwarex/validation_data.R old_vals.csv
suppressMessages(pkgload::load_all(".", quiet = TRUE))
source("tests/testthat/helper-fertoffice.R")
sc <- read.csv("tests/testthat/fixtures/fertoffice_v1.26_scenarios.csv")
r  <- nfert_vs_fertoffice(sc)
o  <- read.csv(commandArgs(TRUE)[1])
out <- data.frame(crop = r$fo_crop, crop_id = r$crop_id,
                  fo_N = r$fo_N_rep, nf_N = r$nf_N_rep, old_N = o$old_N,
                  fo_P = r$fo_P2O5_rep, nf_P = r$nf_P2O5, old_P = o$old_P2O5,
                  fo_K = r$fo_K2O_rep, nf_K = r$nf_K2O, old_K = o$old_K2O)
write.csv(out, "paper/softwarex/data/validation_fertoffice.csv", row.names = FALSE)
