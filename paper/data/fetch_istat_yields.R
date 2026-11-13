#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# fetch_istat_yields.R
#
# Reproducibly pull crop-yield ("resa") figures for SILAGE/FORAGE MAIZE and
# SOFT WHEAT (frumento tenero) in the PIACENZA province (NUTS3 ITD51) and the
# EMILIA-ROMAGNA region (NUTS2 ITD5) from Istat's SDMX web service, and write a
# tidy CSV (istat_yields.csv) used to justify the expected-yield inputs of the
# agrinutri nitrogen-balance paper (CERZOO case-study farm, Po Valley near Piacenza).
#
# DATA SOURCE
#   Istat, "Coltivazioni" (DataSetCode DCSP_COLTIVAZIONI), dataflow IT1:101_1015.
#   SDMX 2.1 REST endpoint: https://esploradati.istat.it/SDMXWS/rest
#   Licence: CC BY 3.0 IT / 4.0 -- "Fonte: Istat".
#
# METHOD NOTE (important)
#   The dataflow does NOT store a ready-made "resa" (yield). It stores AREA and
#   PRODUCTION, so yield is DERIVED here as:
#        resa (q/ha) = produzione raccolta (HP_Q_EXT, quintali)
#                      / superficie          (PA_EXT if present, else ART, ettari)
#        resa (t/ha) = resa (q/ha) / 10        [1 quintale = 100 kg = 0.1 t]
#   For SILAGE MAIZE ("mais ceroso", code CEROIS) the production is FRESH / GREEN
#   forage mass (harvested at waxy stage), NOT dry matter -- hence resa ~40-65
#   t/ha. Do NOT compare it to a dry-matter yield. FODUNIT_EXT ("unita
#   foraggere" / fodder units) is a separate feed-value metric and is ignored.
#   For SOFT WHEAT ("frumento tenero", code COMMEAT) the production is grain.
#
# DIMENSION KEY of the dataflow (order matters for the SDMX data query):
#   FREQ . REF_AREA . DATA_TYPE . TYPE_OF_CROP . DESTINATION_WINEGRAPES  + TIME
#   Codes discovered from the DSD / codelists (references=all) on 2026-07-12:
#     FREQ         : A                          (annual)
#     REF_AREA     : ITD5  = Emilia-Romagna (CL_ITTER107, NUTS2)
#                    ITD51 = Piacenza       (CL_ITTER107, NUTS3)
#     TYPE_OF_CROP : CEROIS  = "mais ceroso"      (silage maize, CL_AGRI_MADRE)
#                    COMMEAT = "frumento tenero"  (soft wheat,   CL_AGRI_MADRE)
#       (FORAIZE "mais da foraggio" and GRAIZE "mais da granella" return NO data
#        for these territories in this flow: Po-Valley silage maize is filed
#        under "mais ceroso".)
#     DATA_TYPE    : left OPEN in the query; the flow returns ART (superficie
#                    totale, ha), PA_EXT (superficie in produzione, ha),
#                    HP_Q_EXT (produzione raccolta, quintali), TP_QUIN_EXT
#                    (produzione totale, quintali), FODUNIT_EXT (unita foraggere)
# ---------------------------------------------------------------------------

## --- configuration ---------------------------------------------------------
here      <- tryCatch(dirname(normalizePath(sub("^--file=", "",
                grep("^--file=", commandArgs(FALSE), value = TRUE)))),
                error = function(e) ".")
if (length(here) == 0 || here == "") here <- "paper/data"
raw_csv   <- file.path(here, "istat_coltivazioni_data.csv")  # SDMX-CSV cache
out_csv   <- file.path(here, "istat_yields.csv")             # tidy output

base <- "https://esploradati.istat.it/SDMXWS/rest"
flow <- "IT1,101_1015,1.0"
key  <- "A.ITD5+ITD51..CEROIS+COMMEAT."        # FREQ.REF_AREA..CROP.(dest empty)
url  <- sprintf("%s/data/%s/%s?startPeriod=2010", base, flow, key)

## --- fetch (cache-first; Istat rate-limits ~5 queries/min) ------------------
# httr/download.file(libcurl) segfault on this R build for these responses, so
# we shell out to the system 'curl' which is reliable here.
if (!file.exists(raw_csv)) {
  message("Fetching from Istat SDMX (SDMX-CSV): ", url)
  code <- system2("curl",
    args = c("-s", "-L", "--max-time", "180",
             "-H", shQuote("Accept: application/vnd.sdmx.data+csv;version=1.0.0"),
             "-o", shQuote(raw_csv), shQuote(url)))
  if (code != 0 || !file.exists(raw_csv))
    stop("Download failed (curl exit ", code, ").")
} else {
  message("Using cached SDMX-CSV: ", raw_csv)
}

d <- read.csv(raw_csv, stringsAsFactors = FALSE, check.names = TRUE)
d <- d[!is.na(suppressWarnings(as.numeric(d$OBS_VALUE))), ]
d$OBS_VALUE <- as.numeric(d$OBS_VALUE)

## --- derive resa ------------------------------------------------------------
terr_lab <- c(ITD5 = "Emilia-Romagna", ITD51 = "Piacenza")
crop_lab <- c(CEROIS  = "silage maize (mais ceroso)",
              COMMEAT = "soft wheat (frumento tenero)")
crop_basis <- c(CEROIS  = "fresh forage (green mass, waxy stage)",
                COMMEAT = "grain (commercial moisture)")

rows <- list()
for (a in names(terr_lab)) for (cc in names(crop_lab)) {
  sub <- d[d$REF_AREA == a & d$TYPE_OF_CROP == cc, ]
  for (y in sort(unique(sub$TIME_PERIOD))) {
    sy   <- sub[sub$TIME_PERIOD == y, ]
    val  <- function(dt) { v <- sy$OBS_VALUE[sy$DATA_TYPE == dt]; if (length(v)) v[1] else NA_real_ }
    hp   <- val("HP_Q_EXT")                       # produzione raccolta (q)
    area <- val("PA_EXT"); if (is.na(area)) area <- val("ART")  # superficie (ha)
    if (is.na(hp) || is.na(area) || area == 0) next
    resa_qha <- hp / area
    rows[[length(rows) + 1]] <- data.frame(
      territory      = terr_lab[[a]],
      territory_code = a,
      crop           = crop_lab[[cc]],
      crop_code      = cc,
      year           = as.integer(y),
      yield_value    = round(resa_qha / 10, 2),       # t/ha
      unit           = "t/ha",
      moisture_basis = crop_basis[[cc]],
      area_ha        = area,
      harvested_prod_q = hp,
      resa_q_ha      = round(resa_qha, 1),
      data_type      = "HP_Q_EXT / (PA_EXT|ART)",
      source         = "Istat, Coltivazioni (DCSP_COLTIVAZIONI), IT1:101_1015; https://esploradati.istat.it/SDMXWS/rest; CC BY 3.0, Fonte: Istat",
      stringsAsFactors = FALSE)
  }
}
res <- do.call(rbind, rows)
res <- res[order(res$territory, res$crop, res$year), ]

write.csv(res, out_csv, row.names = FALSE, fileEncoding = "UTF-8")
message("Wrote ", nrow(res), " rows to ", out_csv)
print(res[res$year >= 2020,
          c("territory","crop","year","yield_value","unit","moisture_basis")],
      row.names = FALSE)
