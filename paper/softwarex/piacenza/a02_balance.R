# Regulatory nitrogen balance for every mapped field of the Piacenza plain and every crop year
# 2019-2026, and its aggregation to crops, municipalities, the mapped plain and the province.
# Inputs: data/fields.rds (a01), data/era5_seasonal.csv (a01), data/istat_piacenza_raw.csv,
# crop_map.csv. Run from the package root:  Rscript paper/softwarex/piacenza/a02_balance.R
# Outputs (aggregated only): data/n_by_crop_year.csv, data/n_by_comune_year.csv,
#                            data/n_province_year.csv
suppressMessages(library(parallel))
pkgload::load_all(".", quiet = TRUE)
HERE <- "paper/softwarex/piacenza"
YEARS <- 2019:2026
fld  <- readRDS(file.path(HERE, "data/fields.rds"))
cmap <- read.csv(file.path(HERE, "crop_map.csv"), stringsAsFactors = FALSE)
rain <- read.csv(file.path(HERE, "data/era5_seasonal.csv"))
names(rain) <- sub("precip_mm.", "", names(rain), fixed = TRUE)

# ---- ISTAT yield (t/ha) and provincial area (ha) by crop and year --------------------
ist <- read.csv(file.path(HERE, "data/istat_piacenza_raw.csv"), stringsAsFactors = FALSE)
w <- reshape(ist[ist$DATA_TYPE %in% c("ART", "HP_Q_EXT"), c("TYPE_OF_CROP", "DATA_TYPE", "TIME_PERIOD", "OBS_VALUE")],
             idvar = c("TYPE_OF_CROP", "TIME_PERIOD"), timevar = "DATA_TYPE", direction = "wide")
names(w) <- c("istat", "year", "area_ha", "prod_q")
w$yield <- w$prod_q / w$area_ha / 10
yield_of <- function(code, crop, y) {
  if (is.na(code) || code == "") return(uptake_table$reference_yield[uptake_table$crop == crop][1])  # DPI reference
  v <- w$yield[w$istat == code & w$year == y]
  if (length(v) && is.finite(v)) v else uptake_table$reference_yield[uptake_table$crop == crop][1]
}

# ---- one task per field and year (maize computed both as grain and as silage) ---------
cls <- function(y) fld[[paste0("c", y)]]
tasks <- do.call(rbind, lapply(YEARS, function(y) {
  cur <- cls(y); prv <- if (y > min(YEARS)) cls(y - 1) else rep(NA, nrow(fld))
  d <- data.frame(i = seq_len(nrow(fld)), year = y, class = cur, prev_class = prv, stringsAsFactors = FALSE)
  mz <- d[d$class %in% c("Maize", "mais"), ]; mz$class <- "Maize (silage)"
  rbind(d, mz)
}))
tasks <- tasks[tasks$class %in% cmap$class, ]
cm <- cmap[match(tasks$class, cmap$class), ]
pv <- cmap$prev_crop[match(tasks$prev_class, cmap$class)]
tasks$prev_crop <- ifelse(is.na(pv), "Undefined", pv)          # unknown or excluded previous class
tasks$crop <- cm$dpi_crop; tasks$ccp <- cm$ccp; tasks$istat <- cm$istat
tasks$yield <- mapply(yield_of, tasks$istat, tasks$crop, tasks$year)
r <- rain[match(paste(fld$cell[tasks$i], tasks$year), paste(rain$cell, rain$crop_year)), ]
tasks$winter_rain <- r$ondj; tasks$feb_rain <- r$feb
cat("field-year tasks:", nrow(tasks), "\n")

one <- function(k) {
  t <- tasks[k, ]; s <- fld[t$i, ]
  if (!all(is.finite(c(s$clay, s$sand, s$corg, s$ntot)))) return(c(NA, NA))
  b <- tryCatch(suppressWarnings(N_balance(
    expected_yield_tons_ha = t$yield, crop = t$crop, ccp = t$ccp,
    sand = s$sand, clay = s$clay, Ntot = s$ntot, SOM = s$corg * 1.724, CN = s$corg * 10 / s$ntot,
    oxygen_availability = "Normal", winter_rain = t$winter_rain, start_spring_rain = t$feb_rain,
    prev_crop = t$prev_crop, source = "None", fertorg_frequency = "every year",
    location = "Isolated plain", forg_quantity = 0)), error = function(e) NULL)
  if (is.null(b)) return(c(NA, NA))
  c(calculate_N_fertilization(b), get_MAS(t$crop)$mas_N)
}
cl <- makeCluster(max(1L, min(8L, detectCores() - 2L)))
clusterEvalQ(cl, { pkgload::load_all(".", quiet = TRUE); NULL })
clusterExport(cl, c("tasks", "fld", "one"))
res <- do.call(rbind, parLapply(cl, seq_len(nrow(tasks)), one))
stopCluster(cl)
tasks$dose <- res[, 1]; tasks$mas <- res[, 2]
tasks$ha <- fld$ha[tasks$i]; tasks$comune <- fld$comune[tasks$i]
cat("failed balances:", sum(is.na(tasks$dose)), "of", nrow(tasks), "\n")

# ---- maize: grain and silage weighted by their provincial area share of the year --------
sh <- merge(w[w$istat == "MAIZE", c("year", "area_ha")], w[w$istat == "CEROIS", c("year", "area_ha")],
            by = "year", suffixes = c("_grain", "_silage"))
sh$p_silage <- sh$area_ha_silage / (sh$area_ha_grain + sh$area_ha_silage)
tasks$weight <- 1
isg <- tasks$class %in% c("Maize", "mais"); iss <- tasks$class == "Maize (silage)"
ps <- sh$p_silage[match(tasks$year, sh$year)]
tasks$weight[isg] <- 1 - ps[isg]; tasks$weight[iss] <- ps[iss]
tasks$group <- ifelse(isg | iss, "Maize", cmap$class[match(tasks$class, cmap$class)])
tasks$group[tasks$class %in% c("cereali vernini")] <- "Winter cereals"
tasks$group[tasks$class %in% c("prato e medica")] <- "Alfalfa"
tasks$group[tasks$class %in% c("pomodoro")] <- "Processing tomato"
tasks$group[tasks$class %in% c("altre estive")] <- "Other summer crops"
tasks$over_mas <- tasks$dose > tasks$mas
ok <- is.finite(tasks$dose)
tasks$N_kg <- tasks$dose * tasks$ha * tasks$weight

agg <- function(by) {
  d <- tasks[ok, ]
  d$ha_w <- d$ha * d$weight; d$over_ha <- d$ha_w * d$over_mas
  a <- aggregate(d[, c("ha_w", "N_kg", "over_ha")], d[, by, drop = FALSE], sum)
  a$dose_mean <- a$N_kg / a$ha_w; a$N_t <- a$N_kg / 1000; a$over_mas_pct <- 100 * a$over_ha / a$ha_w
  a
}
by_crop <- agg(c("year", "group")); by_com <- agg(c("year", "comune"))
write.csv(by_crop, file.path(HERE, "data/n_by_crop_year.csv"), row.names = FALSE)
write.csv(by_com,  file.path(HERE, "data/n_by_comune_year.csv"), row.names = FALSE)

# ---- province: mean dose of the mapped fields x ISTAT provincial area of the crop --------
# Crops without an ISTAT series here (processing tomato, alfalfa, meadows) keep the mapped area.
# 2026 has only 9 classes: winter cereals and other summer crops take the summed ISTAT areas.
pmap <- data.frame(group = c("Soft wheat", "Durum wheat", "Barley", "Soybean", "Sunflower", "Sorghum",
                             rep("Winter cereals", 3), rep("Other summer crops", 3)),
                   istat = c("COMMEAT", "WHEATD", "BARLEY", "SOYA", "SUNFLO", "SORGH",
                             "COMMEAT", "WHEATD", "BARLEY", "SOYA", "SUNFLO", "SORGH"))
pa <- merge(pmap, w[, c("istat", "year", "area_ha")])
pa <- aggregate(area_ha ~ group + year, pa, sum)
prov <- merge(by_crop[, c("year", "group", "dose_mean", "ha_w")], pa, all.x = TRUE)
prov <- prov[prov$group != "Maize", ]
prov$source <- ifelse(is.na(prov$area_ha), "mapped area", "ISTAT area")
prov$area_ha[is.na(prov$area_ha)] <- prov$ha_w[is.na(prov$area_ha)]
mzd <- tasks[ok & (isg | iss), ]
mz <- aggregate(cbind(N = dose * ha, ha) ~ year + class, mzd, sum); mz$dose_mean <- mz$N / mz$ha
mz$istat <- ifelse(mz$class == "Maize (silage)", "CEROIS", "MAIZE")
mz <- merge(mz, w[, c("istat", "year", "area_ha")])
mz$group <- ifelse(mz$class == "Maize (silage)", "Silage maize", "Grain maize"); mz$source <- "ISTAT area"
cols <- c("year", "group", "dose_mean", "area_ha", "source")
prov <- rbind(prov[, cols], mz[, cols])
prov$N_t <- prov$dose_mean * prov$area_ha / 1000
write.csv(prov, file.path(HERE, "data/n_province_year.csv"), row.names = FALSE)
tot <- aggregate(cbind(area_ha, N_t) ~ year, prov, sum)
mapped <- aggregate(cbind(ha_w, N_t) ~ year, by_crop, sum)
print(merge(mapped, tot, by = "year", suffixes = c("_mapped", "_province")))
saveRDS(tasks, file.path(HERE, "data/tasks.rds"))           # field level, stays local (not for release)
