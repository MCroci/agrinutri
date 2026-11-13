# Doses of an earlier NFert release on the Fert_Office validation scenarios.
# Usage (from the package root), with a checkout of the old release in <dir>:
#   git worktree add <dir> 371da70          # NFert 0.14.2 (last commit before 1.0.0)
#   Rscript paper/softwarex/validation_old_release.R <dir> \
#     tests/testthat/fixtures/fertoffice_v1.26_scenarios.csv old_vals.csv
# Then fig2 data: see validation_data.R.
args <- commandArgs(TRUE)
suppressMessages(pkgload::load_all(args[1], quiet = TRUE))
sc <- read.csv(args[2])
ut <- nfert_data_get("uptake_table"); ct <- nfert_data_get("coef_time"); ca <- nfert_data_get("ca.table")
et <- nfert_data_get("e.table"); ft <- nfert_data_get("f.table"); gt <- nfert_data_get("g.table")
freq <- c("every year", "every 2 years", "every 3 years", "occasional")
res <- t(sapply(seq_len(nrow(sc)), function(i) { s <- sc[i, ]
  crop <- ut$crop[match(s$crop_id, ut$id)]
  bal <- suppressWarnings(N_balance(expected_yield_tons_ha = s$yield, crop = crop,
    ccp = ct$ccp[match(s$phase, ct$ID_Fa_D)], sand = s$sand, clay = s$clay, Ntot = s$Ntot, SOM = s$SOM, CN = s$CN,
    oxygen_availability = ca$availability[match(s$id_dre, ca$ID_Dre)], winter_rain = s$winter_rain, start_spring_rain = s$feb_rain,
    prev_crop = et$previous_crop[match(s$id_pre, et$ID_Pre)], source = unique(ft$source[ft$ID_MO == s$id_mo])[1],
    fertorg_frequency = freq[s$id_fre], location = gt$location[match(s$id_ubi, gt$ID_UBI)], forg_quantity = 0,
    organic_previous_year_N = s$org_prev_N, soil_seeding = if (isTRUE(as.logical(s$no_till))) "no-till" else "traditional"))
  p <- suppressWarnings(P_balance(s$yield, crop, olsen_value = s$olsen_P2O5, olsen_unit = "P2O5", clay = s$clay, sand = s$sand))
  k <- suppressWarnings(K_balance(s$yield, crop, k_value = s$K2O, k_unit = "K2O", clay = s$clay, sand = s$sand))
  c(old_N = calculate_N_fertilization(bal), old_P2O5 = p$P2O5_required, old_K2O = k$K2O_required) }))
write.csv(res, args[3], row.names = FALSE)
