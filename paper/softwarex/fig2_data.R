# Data for Fig. 2 (farm example): run from paper/softwarex/ with the package
# source one level up:  Rscript fig2_data.R
suppressMessages(pkgload::load_all("../..", quiet = TRUE))
farm <- sf::st_read(system.file("extdata/example_farm.geojson", package = "NFert"),
                    quiet = TRUE)
out <- farm_balance(farm)
args <- c("expected_yield_tons_ha", "crop", "ccp", "sand", "clay", "Ntot", "SOM",
          "CN", "oxygen_availability", "winter_rain", "start_spring_rain",
          "prev_crop", "source", "fertorg_frequency", "location", "forg_quantity")
terms <- do.call(rbind, lapply(seq_len(nrow(farm)), function(i) {
  a <- as.list(sf::st_drop_geometry(farm)[i, args])
  b <- do.call(N_balance, a)
  data.frame(plot_id = farm$plot_id[i], crop = farm$crop[i], area_ha = farm$area_ha[i],
             A = b$A, B = b$B, C = b$C1 + b$C2, D = b$D, E = b$E, F = b$F,
             Forg = b$Forg, G = b$G, N_dose = calculate_N_fertilization(b),
             MAS = out$MAS_cap[i], MAS_ok = out$MAS_ok[i])
}))
stopifnot(isTRUE(all.equal(round(terms$N_dose, 1), out$N_target)))
write.csv(terms, "data/farm_terms.csv", row.names = FALSE)
geo <- sf::st_transform(out[, c("plot_id", "N_target", "MAS_ok")], 32632)
sf::st_write(geo, "data/farm_plots.geojson", delete_dsn = file.exists("data/farm_plots.geojson"),
             quiet = TRUE)
print(terms, digits = 4)
cat("farm total N (kg):", sum(out$N_total_kg), " area:", sum(farm$area_ha), "\n")
