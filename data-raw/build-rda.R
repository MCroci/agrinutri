# ----------------------------------------------------------------------------
# data-raw/build-rda.R
#
# Rebuild all agrinutri datasets from the canonical CSVs in data-raw/csv/.
# Since agrinutri 0.12.0 the rebuilt .rda files expose the English names as
# the canonical lookup columns (`crop`, `previous_crop`, `fertilizer`,
# `modality_epoch`, `level`, `cycle`, `type`, `phase_duration`) and the
# Italian translations as the secondary `*_it` columns.
#
# Three CSVs still carry Italian as the primary `crop` column with an
# `crop_en` alternative: uptake_table, mas.table, crops.table. For them
# the builder swaps the columns on the fly so the saved .rda is
# consistent with the rest of the package (English canonical).
#
# Usage (one-off, from RStudio with the package as project root):
#
#   source("data-raw/build-rda.R")
#
# This will overwrite the .rda files under data/.
# ----------------------------------------------------------------------------

stopifnot(file.exists("DESCRIPTION"))
csv_dir  <- "data-raw/csv"
data_dir <- "data"
if (!dir.exists(data_dir)) dir.create(data_dir)

read_table_csv <- function(name) {
  fp <- file.path(csv_dir, paste0(name, ".csv"))
  if (!file.exists(fp)) stop(sprintf("Missing CSV: %s", fp))
  df <- utils::read.csv(fp, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
                        check.names = FALSE, na.strings = c("", "NA", "nan"))
  for (j in seq_along(df)) {
    v <- df[[j]]
    if (is.character(v) && all(v %in% c("True","False","TRUE","FALSE", NA))) {
      df[[j]] <- toupper(v) == "TRUE"
    }
  }
  df
}

# Rename / swap columns so that English is always the canonical lookup
# column. Call for every dataframe before it is saved.
promote_english_primary <- function(df, name) {
  # Tables where the Italian column is currently primary and carries
  # the alternative `crop_en` column - swap them so English becomes
  # primary ("crop") and Italian becomes secondary ("crop_it").
  if (name %in% c("uptake_table", "mas.table", "crops.table")) {
    if (all(c("crop", "crop_en") %in% names(df))) {
      it <- df$crop
      en <- df$crop_en
      # When crop_en is NA or empty fall back to the Italian name so
      # that no row becomes unreachable.
      fill <- is.na(en) | !nzchar(en)
      en[fill] <- it[fill]
      df$crop    <- en     # primary lookup column (English)
      df$crop_it <- it     # Italian alias
      df$crop_en <- en     # kept as an alias for internal functions
                           # that look up by `crop_en` (get_MAS, ...)
    }
  }
  df
}

# Fold the few non-ASCII characters of the Italian reference labels
# (degree sign, en/em dash, accented vowels) to ASCII, so the bundled data
# passes R CMD check. Matching in the package is accent-insensitive
# (.agrinutri_ascii_fold in R/crop_lookup.R), so this does not change lookups.
fold_nonascii <- function(df) {
  fold1 <- function(s) {
    s <- gsub(paste0("[", intToUtf8(c(0x2013L, 0x2014L)), "]"), "-", s)
    s <- gsub(intToUtf8(0xB0L), "o", s, fixed = TRUE)
    chartr(intToUtf8(c(0xE0L, 0xE8L, 0xE9L, 0xECL, 0xEDL, 0xF2L, 0xF3L,
                       0xF9L, 0xFAL, 0xC0L, 0xC8L, 0xC9L, 0xCCL, 0xD2L, 0xD9L)),
           "aeeiioouuAEEIOU", s)
  }
  for (j in seq_along(df)) if (is.character(df[[j]])) df[[j]] <- fold1(df[[j]])
  df
}

save_as_rda <- function(df, name) {
  df  <- promote_english_primary(df, name)
  df  <- fold_nonascii(df)
  out <- file.path(data_dir, paste0(name, ".rda"))
  assign(name, df, envir = environment())
  save(list = name, file = out, compress = "xz", version = 2)
  message(sprintf("  wrote %s  (%d x %d)", out, nrow(df), ncol(df)))
}

datasets <- c(
  # Core balance tables
  "uptake_table",
  "mas.table",
  "crops.table",
  "crop_groups.table",
  "e.table",
  "f.table",
  "g.table",
  "coef_time",
  # Soil
  "texture_groups.table",
  "so.table",
  "so_max_input",
  "ph.table",
  "total_carbonate.table",
  "active_carbonate.table",
  # PK availability
  "p_availability.table",
  "p_availability_meta",
  "k_availability.table",
  # Fertilisers
  "fertilizer_types.table",
  "organic_fertilizers.table",
  "efficiency.table",
  "mineral_fertilizers.table",
  # Distribution
  "distribution_modalities.table",
  "cycle_modality.table",
  # Cycles
  "cycles.table",
  "cycle_phases.table",
  # Loss
  "c_d.table",
  # Standard scheda
  "standard_pk_doses.table",
  "standard_decrements.table",
  "standard_increments.table",
  "standard_multicycle.table"
)

message("Rebuilding ", length(datasets), " datasets (English canonical) ...")
for (nm in datasets) {
  df <- read_table_csv(nm)
  save_as_rda(df, nm)
}
message("Done. Now run: devtools::document(); devtools::install()")
