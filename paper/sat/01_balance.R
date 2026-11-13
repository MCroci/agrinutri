# Deterministic balance on the 10 m soil maps and the farm accounting (Table 2).
# Outputs: out/N_mean_10m.tif, data/farm_accounting.csv, data/field_soil_means.csv
source("paper/sat/00_config.R")
soil <- read_soil()
nf <- c(soil$tn * 10, soil$toc * 1.724, soil$clay, soil$sand, soil$toc / soil$tn)
names(nf) <- c("TN", "SOM", "Clay", "Sand", "CNratio")

N <- rast(soil[[1]]); values(N) <- NA; names(N) <- "N"
for (i in seq_len(nrow(FIELDS))) {
  fi <- FIELDS[i, ]
  sub <- mask(nf, soil$field == fi$field_id, maskvalues = FALSE)
  d <- spatial_N_balance(sub, expected_yield_tons_ha = fi$yield, crop = fi$crop, ccp = fi$ccp,
        oxygen_availability = fi$oxygen, winter_rain = fi$winter_rain,
        start_spring_rain = fi$start_spring_rain, prev_crop = fi$prev_crop,
        source = "None", forg_quantity = 0, location = fi$location,
        terms = "N_to_apply")[[1]]
  N <- cover(N, d)
}
writeRaster(N, file.path(OUT, "N_mean_10m.tif"), overwrite = TRUE)

# consistency: the raster path equals the per-pixel function used in the Monte Carlo
chk <- FIELDS[1, ]; px <- which(values(soil$field)[, 1] == chk$field_id)[5]
v <- as.numeric(values(soil)[px, c("clay", "sand", "toc", "tn")])
stopifnot(abs(dose_fn(chk, v[1], v[2], v[3], v[4]) - values(N)[px, 1]) < 1e-9)

area_ha <- as.numeric(st_area(AOI)) / 1e4
acc <- do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i) {
  fi <- FIELDS[i, ]; m <- soil$field == fi$field_id
  nv <- values(mask(N, m, maskvalues = FALSE), na.rm = TRUE)
  a <- area_ha[match(fi$field_id, AOI$field_id)]
  data.frame(field = fi$label, crop = fi$crop, ccp = fi$ccp, yield_t_ha = fi$yield,
             area_ha = a, mean_rate = mean(nv), cv_pct = 100 * sd(nv) / mean(nv),
             N_total_t = mean(nv) * a / 1000)
}))
farm <- data.frame(field = "Farm", crop = NA, ccp = NA, yield_t_ha = NA, area_ha = sum(acc$area_ha),
                   mean_rate = sum(acc$mean_rate * acc$area_ha) / sum(acc$area_ha),
                   cv_pct = NA, N_total_t = sum(acc$N_total_t))
write.csv(rbind(acc, farm), file.path(DAT, "farm_accounting.csv"), row.names = FALSE)

sm <- do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i) {
  m <- soil$field == FIELDS$field_id[i]
  v <- sapply(c("clay", "sand", "toc", "tn"), function(k) global(mask(soil[[k]], m, maskvalues = FALSE), "mean", na.rm = TRUE)[1, 1])
  data.frame(field_id = FIELDS$field_id[i], t(v))
}))
write.csv(sm, file.path(DAT, "field_soil_means.csv"), row.names = FALSE)
print(format(rbind(acc, farm)[, -c(2, 3)], digits = 4))
