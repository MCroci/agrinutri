# ---------------------------------------------------------------------
# Batch run: compute_NNI_from_S2() on every Sentinel-2 scene of a field
# ---------------------------------------------------------------------
#
# For each S2 reflectance .tif in `field_dir` the script:
#   1. runs `estimate_biophysical()` -> LAI / Cm / CNC_Cprot / FVC
#   2. runs `compute_NNI_from_S2()`  -> NNI + zones (and W, N_actual,
#      N_crit, mask if return_intermediates = TRUE)
#   3. writes one sub-folder per date with the GeoTIFFs
#   4. appends per-date summary statistics to `summary.csv`
#   5. optionally stacks all NNI rasters into a single multi-layer
#      time-series .tif at the end.
#
# Usage from R:
#   source("data-raw/run_nni_timeseries.R")
#   res <- nni_timeseries(
#     field_dir = "data-raw/sentinel-2/field_001",
#     crop      = "maize",
#     out_root  = "output/nni-timeseries",
#     cnc_layer = "CNC_Cprot",
#     stack_out = TRUE)
#
# Usage from CLI:
#   Rscript data-raw/run_nni_timeseries.R \
#     data-raw/sentinel-2/field_001 maize output/nni-timeseries
# ---------------------------------------------------------------------

suppressPackageStartupMessages({
  library(agrinutri)
  library(terra)
})

# Pull the date `YYYYMMDD` (or `YYYY-MM-DD`) out of the filename. Returns
# a Date object, NA if no match.
.parse_s2_date <- function(file) {
  m <- regmatches(basename(file),
                  regexpr("(20\\d{6})", basename(file)))
  if (!length(m) || !nzchar(m)) return(as.Date(NA))
  as.Date(m, format = "%Y%m%d")
}

#' Run the S2->NNI pipeline on every scene in a field folder.
#'
#' @param field_dir  folder containing one .tif per acquisition date
#' @param crop       crop name accepted by crop_params_NNI()
#' @param out_root   parent folder for outputs (one sub-folder per scene)
#' @param cnc_layer  "CNC_Cprot" (default) or "CNC_Cab"
#' @param fvc_mask   logical, apply FVC>=fvc_min mask (default TRUE)
#' @param pattern    regex to filter scenes (default Sentinel-2 GeoTIFFs)
#' @param stack_out  if TRUE write a multi-layer NNI time-series .tif
#' @param overwrite  if TRUE re-process scenes whose output already exists
#'
#' @return a data.frame with one row per date: date, n_pixels_in,
#'   n_pixels_kept, mean_NNI, sd_NNI, pct_def, pct_opt, pct_exc, status,
#'   nni_path, zones_path.
nni_timeseries <- function(field_dir,
                           crop,
                           out_root,
                           cnc_layer    = c("CNC_Cprot", "CNC_Cab"),
                           fvc_mask     = TRUE,
                           fvc_min      = NULL,    # NULL = use crop default
                           w_min        = NULL,    # NULL = use crop default
                           apply_offset = FALSE,   # offset-applied reflectance
                           scale        = 10000,   # change to 1 for float
                           nodata_in    = 0,
                           pattern      = "^S2_.*\\.tif$",
                           stack_out    = TRUE,
                           overwrite    = FALSE) {

  cnc_layer <- match.arg(cnc_layer)
  if (!dir.exists(field_dir))
    stop("field_dir does not exist: ", field_dir)
  dir.create(out_root, showWarnings = FALSE, recursive = TRUE)

  scenes <- list.files(field_dir, pattern = pattern,
                       full.names = TRUE, ignore.case = TRUE)
  if (!length(scenes))
    stop("No scenes match pattern '", pattern, "' in ", field_dir)

  message(sprintf("[agrinutri] Found %d scenes in %s", length(scenes),
                  field_dir))

  log <- vector("list", length(scenes))
  for (i in seq_along(scenes)) {
    scene <- scenes[[i]]
    date  <- .parse_s2_date(scene)
    tag   <- if (is.na(date)) sprintf("scene_%03d", i)
             else format(date, "%Y%m%d")
    sub   <- file.path(out_root, tag)

    nni_path   <- file.path(sub, "NNI.tif")
    zones_path <- file.path(sub, "zones.tif")

    # Skip if already done and not forced
    if (!overwrite && file.exists(nni_path) && file.exists(zones_path)) {
      message(sprintf("[%2d/%d] %s  -- already processed, skipping",
                      i, length(scenes), tag))
      log[[i]] <- .summarise_existing(date, nni_path, zones_path,
                                      sub, status = "cached")
      next
    }

    dir.create(sub, showWarnings = FALSE, recursive = TRUE)
    message(sprintf("[%2d/%d] %s  -- biophysical retrieval...",
                    i, length(scenes), tag))

    # 1. GPR retrieval
    biop <- tryCatch(
      estimate_biophysical(
        raster_path  = scene, output_dir = sub,
        variables    = c("LAI", "Cm", cnc_layer, "FVC"),
        apply_offset = apply_offset,
        scale        = scale,
        nodata_in    = nodata_in,
        block_rows   = 256),
      error = function(e) e)

    if (inherits(biop, "error")) {
      warning(sprintf("Scene %s failed at GPR step: %s",
                      tag, conditionMessage(biop)))
      log[[i]] <- data.frame(
        date          = date,
        n_pixels_in   = NA_integer_,
        n_pixels_kept = NA_integer_,
        mean_NNI      = NA_real_,
        sd_NNI        = NA_real_,
        pct_def       = NA_real_,
        pct_opt       = NA_real_,
        pct_exc       = NA_real_,
        status        = "gpr_error",
        nni_path      = NA_character_,
        zones_path    = NA_character_,
        stringsAsFactors = FALSE)
      next
    }

    # 2. NNI pipeline
    message(sprintf("[%2d/%d] %s  -- NNI pipeline...",
                    i, length(scenes), tag))
    # Build per-call params: start from crop defaults, override fvc_min /
    # w_min only if the user supplied them.
    user_params <- crop_params_NNI(crop)
    if (!is.null(fvc_min)) user_params$fvc_min <- fvc_min
    if (!is.null(w_min))   user_params$w_min   <- w_min

    nni <- tryCatch(
      compute_NNI_from_S2(
        lai_rast  = biop$LAI,
        cm_rast   = biop$Cm,
        cnc_rast  = biop[[cnc_layer]],
        cnc_layer = cnc_layer,
        crop      = crop,
        params    = user_params,
        fvc       = if (isTRUE(fvc_mask)) biop$FVC else NULL,
        return_intermediates = TRUE),
      error = function(e) e)

    if (inherits(nni, "error")) {
      warning(sprintf("Scene %s failed at NNI step: %s",
                      tag, conditionMessage(nni)))
      log[[i]] <- data.frame(
        date          = date,
        n_pixels_in   = NA_integer_,
        n_pixels_kept = NA_integer_,
        mean_NNI      = NA_real_,
        sd_NNI        = NA_real_,
        pct_def       = NA_real_,
        pct_opt       = NA_real_,
        pct_exc       = NA_real_,
        status        = "nni_error",
        nni_path      = NA_character_,
        zones_path    = NA_character_,
        stringsAsFactors = FALSE)
      next
    }

    # 3. Persist
    terra::writeRaster(nni$NNI,      nni_path,   overwrite = TRUE)
    terra::writeRaster(nni$zones,    zones_path, overwrite = TRUE)
    if (!is.null(nni$W))
      terra::writeRaster(nni$W,
                         file.path(sub, "W.tif"),        overwrite = TRUE)
    if (!is.null(nni$N_actual))
      terra::writeRaster(nni$N_actual,
                         file.path(sub, "N_actual.tif"), overwrite = TRUE)
    if (!is.null(nni$N_crit))
      terra::writeRaster(nni$N_crit,
                         file.path(sub, "N_crit.tif"),   overwrite = TRUE)

    # 4. Summary stats
    log[[i]] <- .summarise_nni(date, nni, nni_path, zones_path,
                               status = "ok")
  }

  out <- do.call(rbind, log)
  out <- out[order(out$date), , drop = FALSE]
  rownames(out) <- NULL

  csv_path <- file.path(out_root, "summary.csv")
  utils::write.csv(out, csv_path, row.names = FALSE)
  message(sprintf("[agrinutri] Summary written to %s", csv_path))

  # 5. Optional NNI time-series stack
  if (isTRUE(stack_out)) {
    ok <- out$status == "ok" | out$status == "cached"
    if (sum(ok) >= 2) {
      message("[agrinutri] Stacking NNI rasters into a single .tif...")
      stk <- tryCatch({
        rs <- lapply(out$nni_path[ok], terra::rast)
        # Align to first scene's grid, in case of small differences
        rs <- lapply(rs, function(r) terra::resample(r, rs[[1]]))
        s <- terra::rast(rs)
        names(s) <- format(out$date[ok], "%Y%m%d")
        s
      }, error = function(e) {
        warning("Stacking failed: ", conditionMessage(e))
        NULL
      })
      if (!is.null(stk)) {
        stack_path <- file.path(out_root, "NNI_timeseries.tif")
        terra::writeRaster(stk, stack_path, overwrite = TRUE)
        message(sprintf("[agrinutri] Time-series stack -> %s", stack_path))
      }
    } else {
      message("[agrinutri] Need >= 2 successful scenes to stack -- skipped.")
    }
  }

  invisible(out)
}

# ---- internal helpers -------------------------------------------------

.summarise_nni <- function(date, nni, nni_path, zones_path, status) {
  mask_vals <- terra::values(nni$mask, na.rm = TRUE)
  n_in   <- length(mask_vals)
  n_keep <- sum(mask_vals > 0, na.rm = TRUE)

  vals <- terra::values(nni$NNI, na.rm = TRUE)
  zns  <- terra::values(nni$zones, na.rm = TRUE)

  pct <- function(x, val) {
    if (!length(x)) return(NA_real_)
    100 * sum(x == val, na.rm = TRUE) / length(x)
  }

  data.frame(
    date          = date,
    n_pixels_in   = as.integer(n_in),
    n_pixels_kept = as.integer(n_keep),
    mean_NNI      = if (length(vals)) mean(vals) else NA_real_,
    sd_NNI        = if (length(vals)) stats::sd(vals)   else NA_real_,
    pct_def       = pct(zns, 1),
    pct_opt       = pct(zns, 2),
    pct_exc       = pct(zns, 3),
    status        = status,
    nni_path      = normalizePath(nni_path,   mustWork = FALSE),
    zones_path    = normalizePath(zones_path, mustWork = FALSE),
    stringsAsFactors = FALSE)
}

.summarise_existing <- function(date, nni_path, zones_path, sub, status) {
  r <- terra::rast(nni_path)
  z <- terra::rast(zones_path)
  vals <- terra::values(r, na.rm = TRUE)
  zns  <- terra::values(z, na.rm = TRUE)
  pct <- function(x, val) {
    if (!length(x)) return(NA_real_)
    100 * sum(x == val, na.rm = TRUE) / length(x)
  }
  data.frame(
    date          = date,
    n_pixels_in   = NA_integer_,
    n_pixels_kept = as.integer(length(vals)),
    mean_NNI      = if (length(vals)) mean(vals) else NA_real_,
    sd_NNI        = if (length(vals)) stats::sd(vals)   else NA_real_,
    pct_def       = pct(zns, 1),
    pct_opt       = pct(zns, 2),
    pct_exc       = pct(zns, 3),
    status        = status,
    nni_path      = normalizePath(nni_path,   mustWork = FALSE),
    zones_path    = normalizePath(zones_path, mustWork = FALSE),
    stringsAsFactors = FALSE)
}

# ---- CLI entry --------------------------------------------------------
# Rscript data-raw/run_nni_timeseries.R FIELD_DIR CROP OUT_ROOT
if (!interactive() && length(commandArgs(trailingOnly = TRUE))) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 3)
    stop("Usage: Rscript run_nni_timeseries.R FIELD_DIR CROP OUT_ROOT")
  nni_timeseries(field_dir = args[1],
                 crop      = args[2],
                 out_root  = args[3])
}
