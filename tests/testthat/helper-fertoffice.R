# Test helper: compare agrinutri with Fert_Office v1.26 on the scenarios produced by
# data-raw/fertoffice_validation.py. Used by
# tests/testthat/test-fertoffice-validation.R.

agrinutri_vs_fertoffice <- function(sc) {
  ut  <- agrinutri:::agrinutri_data_get("uptake_table")
  ct  <- agrinutri:::agrinutri_data_get("coef_time")
  ca  <- agrinutri:::agrinutri_data_get("ca.table")
  et  <- agrinutri:::agrinutri_data_get("e.table")
  ft  <- agrinutri:::agrinutri_data_get("f.table")
  gt  <- agrinutri:::agrinutri_data_get("g.table")
  freq <- c("every year", "every 2 years", "every 3 years", "occasional")
  one <- function(s) {
    crop <- ut$crop[match(s$crop_id, ut$id)]
    src  <- unique(ft$source[ft$ID_MO == s$id_mo])[1]
    bal <- N_balance(
      expected_yield_tons_ha = s$yield, crop = crop,
      ccp = ct$ccp[match(s$phase, ct$ID_Fa_D)],
      sand = s$sand, clay = s$clay, Ntot = s$Ntot, SOM = s$SOM, CN = s$CN,
      oxygen_availability = ca$availability[match(s$id_dre, ca$ID_Dre)],
      winter_rain = s$winter_rain, start_spring_rain = s$feb_rain,
      prev_crop = et$previous_crop[match(s$id_pre, et$ID_Pre)],
      source = src, fertorg_frequency = freq[s$id_fre],
      location = gt$location[match(s$id_ubi, gt$ID_UBI)],
      forg_quantity = 0, organic_previous_year_N = s$org_prev_N,
      soil_seeding = if (isTRUE(as.logical(s$no_till))) "no-till" else "traditional")
    p <- P_balance(s$yield, crop, olsen_value = s$olsen_P2O5,
                   olsen_unit = "P2O5", clay = s$clay, sand = s$sand,
                   total_carbonate = s$CaCO3_tot)
    k <- K_balance(s$yield, crop, k_value = s$K2O, k_unit = "K2O",
                   clay = s$clay, sand = s$sand)
    data.frame(
      nf_A = bal$A, nf_B = bal$B, nf_C = bal$C1 + bal$C2, nf_D = bal$D,
      nf_E = bal$E, nf_F = bal$F, nf_G = bal$G,
      nf_N = bal$A + bal$C1 + bal$C2 + bal$D - bal$B - bal$E - bal$F - bal$G,
      nf_N_rep = calculate_N_fertilization(bal),
      nf_P_A = p$A, nf_P_B1 = p$B1, nf_P_B2 = p$B2,
      nf_P2O5 = p$P2O5_required,
      nf_K_A = k$A, nf_K_H = k$H, nf_K_F1 = k$B1, nf_K_F2 = k$B2,
      nf_K2O = k$K2O_required)
  }
  res <- do.call(rbind, lapply(seq_len(nrow(sc)), function(i)
    suppressWarnings(suppressMessages(one(sc[i, ])))))
  cbind(sc, res)
}
