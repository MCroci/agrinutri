#' Fold the few non-ASCII characters of the Italian reference labels
#' (degree sign, en/em dash, accented vowels) to ASCII. Used both when
#' building the bundled data and when matching user input, so lookups stay
#' accent-insensitive while the data remains ASCII (CRAN requirement).
#' @noRd
.nfert_ascii_fold <- function(s) {
  s <- as.character(s)
  # Build the non-ASCII characters from code points so this source file
  # stays pure ASCII. en/em dash -> hyphen; degree sign -> "o"; accented
  # vowels -> base letter via a 1:1 chartr() map.
  s <- gsub(paste0("[", intToUtf8(c(0x2013L, 0x2014L)), "]"), "-", s)
  s <- gsub(intToUtf8(0xB0L), "o", s, fixed = TRUE)
  from <- intToUtf8(c(0xE0L, 0xE8L, 0xE9L, 0xECL, 0xEDL, 0xF2L, 0xF3L,
                      0xF9L, 0xFAL, 0xC0L, 0xC8L, 0xC9L, 0xCCL, 0xD2L, 0xD9L))
  to   <- "aeeiioouuAEEIOU"
  chartr(from, to, s)
}

#' @noRd
.crop_alias_to_canonical <- function() {
  # Only truly non-obvious variants that are neither in the English
  # canonical `crop` column nor in the Italian translation `crop_it`.
  # Standard Italian / English crop names are resolved directly against
  # the table columns by `resolve_crop()`.
  stats::setNames(
    c(
      "Silage maize (class 700)",
      "Silage maize (class 700)",
      "Silage maize (class 700)",
      "Silage maize (class 500)",
      "Soft wheat FF - strong (grain)",
      "Soft wheat FF - strong (whole plant)"
    ),
    c(
      "Mais trinciato (classe 700)",
      "Mais da insilato (classe 700)",
      "Shredded corn class 700",
      "Mais da insilato (classe 500)",
      "Soft wheat FF",
      "Soft wheat FF (whole)"
    )
  )
}

#' Resolve a crop name (Italian or English) to its canonical entry
#'
#' NFert reference tables (`uptake_table`, `mas.table`, `crops.table`,
#' `standard_pk_doses.table`) carry the canonical English crop names in
#' the column `crop` (since NFert 0.12.0), with the Italian translation
#' in `crop_it` and a duplicate of the English name in `crop_en` for
#' backward compatibility. This helper accepts any of the three forms
#' (case-insensitive, whitespace-normalised, exact match) and returns
#' the canonical English key used for joins downstream.
#'
#' If the input matches none of the columns, the input is returned
#' unchanged together with a warning.
#'
#' @param x Character. Crop name in Italian or English.
#' @param table Lookup table; default `NFert::uptake_table`.
#' @return Character. The canonical crop name (English, as in the
#'   `crop` column).
#' @examples
#' resolve_crop("Durum wheat (grain)")
#' resolve_crop("Grano duro (granella)")
#' resolve_crop("Mais trinciato classe 700")
#' @export
resolve_crop <- function(x, table = nfert_data_get("uptake_table")) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    stop("`x` must be a single non-NA character.")
  }
  # Normalise: fold accents to ASCII, trim and collapse internal spaces, so
  # matching is accent-insensitive and works against the ASCII-folded data.
  norm <- function(s) .nfert_ascii_fold(gsub("\\s+", " ", trimws(s)))
  xn <- norm(x)

  # Apply known aliases (rare names / alternate spellings)
  amap <- .crop_alias_to_canonical()
  i_alias <- match(tolower(xn), tolower(names(amap)))
  if (!is.na(i_alias)) xn <- norm(amap[i_alias])

  # 1. Direct match on the primary column (English canonical since 0.12.0)
  crop_norm <- norm(as.character(table$crop))
  i <- which(tolower(crop_norm) == tolower(xn))
  if (length(i) > 0) return(as.character(table$crop[i[1]]))

  # 2. Match on the Italian translation column (if present)
  if ("crop_it" %in% names(table)) {
    it_norm <- norm(as.character(table$crop_it))
    i <- which(tolower(it_norm) == tolower(xn))
    if (length(i) > 0) return(as.character(table$crop[i[1]]))
  }

  # 3. Match on the crop_en alias column (mirrors crop after 0.12.0;
  #    useful for legacy tables where crop was Italian and crop_en
  #    held the English form)
  if ("crop_en" %in% names(table)) {
    en_norm <- norm(as.character(table$crop_en))
    i <- which(tolower(en_norm) == tolower(xn))
    if (length(i) > 0) return(as.character(table$crop[i[1]]))
  }

  warning(sprintf("Crop '%s' not found in lookup; returning input as-is.", x))
  x
}

#' Resolve a `ccp` (crop calendar period) string with whitespace and dash
#' normalisation
#'
#' Handles common variations between user input and the canonical English
#' value stored in `coef_time$ccp`:
#' \itemize{
#'   \item Trims outer whitespace and collapses internal multiple spaces.
#'   \item Replaces en-dash (U+2013) and em-dash (U+2014) with hyphen.
#'   \item Case-insensitive match.
#' }
#'
#' @param x Character. The `ccp` string to resolve.
#' @param table Lookup with column `ccp`; default `NFert::coef_time`.
#' @return The canonical `ccp` string (as in `table$ccp`), or `x` unchanged
#'   with a warning if not found.
#' @examples
#' resolve_ccp("Spring-summer crop 100\u2013130 days")  # em-dash
#' resolve_ccp("autumn-winter crop <150 days")         # case
#' @export
resolve_ccp <- function(x, table = nfert_data_get("coef_time")) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    stop("`x` must be a single non-NA character.")
  }
  norm <- function(s) {
    s <- .nfert_ascii_fold(s)             # degree / dash / accents -> ASCII
    s <- gsub("\\bcrop\\b", "", s, ignore.case = TRUE)  # optional "crop" word
    s <- gsub("\\s+", " ", trimws(s))
    tolower(s)
  }
  xn <- norm(x)
  cands <- norm(as.character(table$ccp))
  i <- which(cands == xn)
  if (length(i) > 0) return(as.character(table$ccp[i[1]]))
  # Last-resort: also try Italian alias if present
  if ('ccp_it' %in% names(table)) {
    cands_it <- norm(as.character(table$ccp_it))
    i <- which(cands_it == xn)
    if (length(i) > 0) return(as.character(table$ccp[i[1]]))
  }
  warning(sprintf("ccp '%s' not found in coef_time$ccp; returning input as-is.", x))
  x
}

#' List all crops with both Italian and English names
#'
#' @return A data frame with columns `crop` (Italian, canonical) and
#'   `crop_en` (English).
#' @examples
#' head(list_crops())
#' @export
list_crops <- function() {
  ut <- nfert_data_get("uptake_table")
  if (!('crop_en' %in% names(ut))) {
    return(data.frame(crop = ut$crop, crop_en = ut$crop, stringsAsFactors = FALSE))
  }
  data.frame(crop = ut$crop, crop_en = ut$crop_en, stringsAsFactors = FALSE)
}

# Crop attributes from crops.table (Fert_Office foglio "Coltura") used by the
# N balance: proposed N-fixation share (%) and default ceiling on the dose.
.crop_info <- function(crop) {
  out <- list(n_fixation_pct = 0, N_limit = 340)
  ct <- tryCatch(nfert_data_get("crops.table"), error = function(e) NULL)
  if (is.null(ct)) return(out)
  norm <- function(x) .nfert_ascii_fold(tolower(gsub("[[:space:]]+", " ", trimws(as.character(x)))))
  key <- norm(crop)
  i <- match(key, norm(ct$crop))
  if (is.na(i) && "crop_it" %in% names(ct)) i <- match(key, norm(ct$crop_it))
  if (is.na(i)) {
    rc <- suppressWarnings(resolve_crop(crop))
    i <- match(norm(rc), norm(ct$crop))
  }
  if (is.na(i)) return(out)
  fp <- suppressWarnings(as.numeric(ct$n_fixation_pct[i]))
  lim <- suppressWarnings(as.numeric(ct$N_limit[i]))
  if (is.finite(fp)) out$n_fixation_pct <- fp
  if (is.finite(lim)) out$N_limit <- lim
  out
}
