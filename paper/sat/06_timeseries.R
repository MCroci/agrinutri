# Farm-scale canopy trajectories for Figure 3: leaf area index and canopy nitrogen content
# (CNC_Cprot, g N m-2) retrieved by Gaussian-process regression from every Sentinel-2 Level-2A
# scene from October 2024 to October 2025 of the dense archive, cloud-masked with the scene
# classification (SCL classes 4 to 7 kept), averaged per field.
# Output: data/timeseries_fields.csv
Sys.setenv(SAT_SCENARIO = "reference"); source("paper/sat/00_config.R")
D <- file.path(ROOT, "data/rasters/downloads_sentinelhub_2019_2026")
S2B <- c("B02","B03","B04","B05","B06","B07","B08","B8A","B11","B12")
f <- list.files(D, pattern = "^S2_[0-9]{8}_.*SCL_10m[.]tif$", full.names = TRUE)
dt <- as.Date(regmatches(basename(f), regexpr("[0-9]{8}", basename(f))), "%Y%m%d")
keep <- dt >= as.Date("2024-10-01") & dt <= as.Date("2025-10-31")
f <- f[keep]; dt <- dt[keep]
av <- vect(AOI); tmp <- tempfile("ts"); dir.create(tmp)
rows <- list()
for (k in seq_along(f)) {
  r <- rast(f[k])
  if (!same.crs(r, av)) r <- project(r, "EPSG:32632")
  scl <- round(r[[11]] / 10000)                       # every band, SCL included, is scaled x 10000
  s2 <- mask(r[[1:10]], scl %in% 4:7, maskvalues = FALSE); names(s2) <- S2B
  s2 <- crop(s2, av)
  if (global(!is.na(s2[[1]]), "mean")[1, 1] < 0.3) next           # mostly cloud
  p <- file.path(tmp, sprintf("s2_%d.tif", k)); writeRaster(s2, p, overwrite = TRUE, NAflag = 0)
  m <- tryCatch(estimate_biophysical(p, output_dir = file.path(tmp, k), variables = c("LAI", "CNC_Cprot")),
                error = function(e) NULL)
  if (is.null(m)) next
  for (i in seq_len(nrow(AOI))) {
    v <- extract(c(m$LAI, m$CNC_Cprot), av[i], ID = FALSE)
    ok <- complete.cases(v)
    if (mean(ok) < 0.5) next                           # field mostly cloud-masked on that date
    rows[[length(rows) + 1L]] <- data.frame(date = dt[k], field = AOI$label[i],
      LAI = mean(v[ok, 1]), CNC = mean(v[ok, 2]), valid = mean(ok))
  }
  cat(format(dt[k]), "\n")
}
write.csv(do.call(rbind, rows), file.path(DAT, "timeseries_fields.csv"), row.names = FALSE)
