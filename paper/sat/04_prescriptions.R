# Prescriptions on the CERZOO farm (Section 3.2): five strategies on 24 m x 30 m cells,
# 24 m strips, four machine geometries and the cell-size fidelity. Every prescription keeps
# the field mean at the field target N* = min(balance dose, MAS).
# Outputs: out/strategies.geojson, out/farm_strips.geojson, out/grids_<w>.geojson,
#          data/strategy_summary.csv, data/strip_summary.csv, data/cellsize_fidelity.csv
source("paper/sat/00_config.R")
Nrast <- rast(file.path(OUT, "N_mean_10m.tif"))
fld_n <- function(i) terra::extract(Nrast, vect(AOI[i, ]), fun = mean, na.rm = TRUE)[, 2]
mas <- function(i) get_MAS(FIELDS$crop[i])$mas_N
DIAG <- "paper/sat/out"
rd <- function(prefix, id) rast(file.path(DIAG, sprintf("%s_%d.tif", prefix, id)))
rd0 <- function(prefix, id) { r <- rd(prefix, id); r }
strat <- list(list(n = "Uniform", v = "uniform"),
              list(n = "Calibration (inverse)", v = "calibration", inv = TRUE),
              list(n = "Calibration (direct)",  v = "calibration", inv = FALSE),
              list(n = "Quantile classes", v = "classes", inv = TRUE),
              list(n = "NNI zones", v = "nni"))
build <- function(i, s, w, cl, nt) {
  fid <- FIELDS$field_id[i]
  build_strip_prescription(AOI[i, ], machine_width = w, cell_length = cl, variability = s$v,
    vi_raster = rd("ndvi", fid), nni_raster = rd("nni", fid), n_target = nt,
    min_dose = nt * 0.6, max_dose = nt * 1.35,
    calibration_inverse = if (!is.null(s$inv)) s$inv else TRUE, preserve_mean = TRUE)
}
stamp <- function(x, ...) { x <- x[, "dose"]; for (k in names(list(...))) x[[k]] <- list(...)[[k]]; x }

tgt <- sapply(seq_len(nrow(FIELDS)), function(i) min(fld_n(i), mas(i)))
names(tgt) <- FIELDS$label
write.csv(data.frame(field = FIELDS$label, balance = sapply(seq_len(nrow(FIELDS)), fld_n),
                     mas = sapply(seq_len(nrow(FIELDS)), mas), target = tgt),
          file.path(DAT, "field_targets.csv"), row.names = FALSE)

# five strategies, 24 m x 30 m cells
S <- do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i) do.call(rbind, lapply(strat, function(s)
  stamp(build(i, s, 24, 30, tgt[i]), strategy = s$n, field = FIELDS$label[i], target = tgt[i])))))
S$strategy <- factor(S$strategy, levels = sapply(strat, `[[`, "n"))
st_write(S, file.path(OUT, "strategies.geojson"), delete_dsn = TRUE, quiet = TRUE)
ss <- do.call(rbind, lapply(split(S, S$strategy), function(d) {
  m <- tapply(seq_len(nrow(d)), d$field, function(ix) weighted.mean(d$dose[ix], as.numeric(st_area(d[ix, ]))))
  rel <- d$dose / d$target
  data.frame(strategy = d$strategy[1], min_rel = 100 * min(rel), max_rel = 100 * max(rel),
             sd_kg_ha = sd(d$dose), max_mean_dev = max(abs(m - tgt[names(m)])))
}))
write.csv(ss, file.path(DAT, "strategy_summary.csv"), row.names = FALSE); print(ss)

# 24 m strips (calibration, inverse): the farm-monitor delivery of Fig. 6c
cal <- strat[[2]]
strips <- do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i)
  stamp(build(i, cal, 24, 0, tgt[i]), field = FIELDS$label[i])))
st_write(strips, file.path(OUT, "farm_strips.geojson"), delete_dsn = TRUE, quiet = TRUE)
write.csv(data.frame(width = 24, passes = nrow(strips)), file.path(DAT, "strip_summary.csv"), row.names = FALSE)

# four machine geometries (width = cell length), NDVI-driven
gs <- c(12, 18, 24, 36); counts <- integer()
for (w in gs) {
  g <- do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i) stamp(build(i, cal, w, w, tgt[i]), field = FIELDS$label[i])))
  g$width <- w; counts[as.character(w)] <- nrow(g)
  st_write(g, file.path(OUT, sprintf("grids_%d.geojson", w)), delete_dsn = TRUE, quiet = TRUE)
}
write.csv(data.frame(width = gs, cells = counts), file.path(DAT, "grid_counts.csv"), row.names = FALSE)

# fidelity of coarser square grids to the finest (10 m) prescription (R^2, mean over fields)
within <- list(strat[[2]], strat[[4]], strat[[5]])
sizes <- c(10, 15, 20, 24, 30, 40, 50, 60)
fid <- do.call(rbind, lapply(within, function(s) do.call(rbind, lapply(seq_len(nrow(FIELDS)), function(i) {
  ref <- build(i, s, 10, 10, tgt[i]); ctr <- st_centroid(st_geometry(ref))
  do.call(rbind, lapply(sizes, function(cs) {
    cg <- build(i, s, cs, cs, tgt[i])
    hit <- st_intersects(ctr, cg); d <- vapply(hit, function(h) if (length(h)) cg$dose[h[1]] else NA_real_, numeric(1))
    ok <- is.finite(d) & is.finite(ref$dose)
    data.frame(strategy = s$n, field = FIELDS$label[i], cell_m = cs,
               r2 = if (sd(d[ok]) > 0 && sd(ref$dose[ok]) > 0) cor(d[ok], ref$dose[ok])^2 else NA_real_)
  }))
}))))
write.csv(aggregate(r2 ~ strategy + cell_m, fid, mean), file.path(DAT, "cellsize_fidelity.csv"), row.names = FALSE)
print(aggregate(r2 ~ strategy + cell_m, fid, mean))
