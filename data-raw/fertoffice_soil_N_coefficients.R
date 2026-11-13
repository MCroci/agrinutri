# Soil-N supply coefficients of the DPI balance, aligned with Fert_Office v1.26.
#
# Fert_Office (foglio "B") computes, for the 20 cm topsoil layer of weight W
# (t/ha: 2800 sandy, 2600 loamy, 2400 clay; Ragg_Tes),
#   N pronto      = W * min(Ntot, 2.1) / 1000 * 1000 * 0.01  = (W / 100) * Ntot
#   N mineralised = W * min(SO, 3) / 100 * 1000 * k / 100 * 0.05
#                 = (W * k / 200) * SO
# where k is the yearly SOM decomposition rate (%) by texture and C/N class
# (foglio "B", J2:M11). The per-unit coefficients below are therefore W/100
# and W*k/200. They follow the footnote of DPI Allegato 2, Tab. 1, which the
# printed table rounds differently (e.g. 36 instead of 35 for sandy soils with
# a balanced C/N).
#
# Run from the package root: source("data-raw/fertoffice_soil_N_coefficients.R")

W <- c("Sandy textures" = 2800, "Loamy textures" = 2600, "Clay textures" = 2400)

coefN_readily <- data.frame(
  id = 1:3,
  group = names(W),
  coef.N.readily = unname(W / 100),
  stringsAsFactors = FALSE
)

k <- data.frame(
  group    = rep(names(W), 3),
  CN_ratio = rep(c("9-12", "<9", ">12"), each = 3),
  k        = c(2.5, 1.85, 1.0,    # balanced C/N
               3.0, 2.0, 1.5,     # C/N < 9
               2.0, 1.7, 0.5),    # C/N > 12
  stringsAsFactors = FALSE
)
coefN_mineralised <- data.frame(
  id = 1:9,
  group = k$group,
  coef.N.mineralised = unname(W[k$group] * k$k / 200),
  CN_ratio = k$CN_ratio,
  stringsAsFactors = FALSE
)

save(coefN_readily, file = "data/coefN_readily.rda", compress = "bzip2")
save(coefN_mineralised, file = "data/coefN_mineralised.rda", compress = "bzip2")
