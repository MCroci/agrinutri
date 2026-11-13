# global.R -- loaded once when the Shiny app starts.
# Defines constants, helpers and loads the module UI/server functions.

suppressPackageStartupMessages({
  library(shiny)
  library(shinyjs)
  library(DT)
  library(ggplot2)
  if (!requireNamespace("agrinutri", quietly = TRUE))
    stop("Package 'agrinutri' must be installed to run the Shiny app.")
  library(agrinutri)
})

# Runtime constants
APP_VERSION <- tryCatch(
  as.character(utils::packageVersion("agrinutri")),
  error = function(e) "0.9.0"
)
APP_BUILD   <- format(Sys.Date(), "%Y-%m-%d")

# --- Helpers shared by several modules -------------------------------

# Crop choice list. Starting with agrinutri 0.12.0 the reference tables are
# English-canonical, so list_crops() already returns English names; we
# use them both as label and as value (identity named vector).
.agrinutri_crop_choices <- function() {
  en_names <- tryCatch({
    ct <- agrinutri::list_crops()
    if (is.data.frame(ct) && "crop" %in% names(ct))
      sort(unique(as.character(ct$crop)))
    else sort(as.character(ct))
  },
  error = function(e) names(agrinutri::crop_en2it))
  setNames(en_names, en_names)
}

.agrinutri_default_crop <- function() {
  d <- .agrinutri_crop_choices()
  want <- "Silage maize (class 700)"
  if (want %in% d) want else d[[1]]
}

# English-only labels for the domain-specific dropdowns. Values are the
# canonical keys expected by the agrinutri reference tables (Italian where
# required). Visible labels on the left, canonical values on the right.
.CCP_CHOICES <- c(
  "Spring-summer crop <70 days"     = "Spring-summer crop <70 days",
  "Spring-summer crop 70-100 days"  = "Spring-summer crop 70-100 days",
  "Spring-summer crop 100-130 days" = "Spring-summer crop 100-130 days",
  "Spring-summer crop >130 days"    = "Spring-summer crop >130 days",
  "Autumn-winter crop <150 days"    = "Autumn-winter crop <150 days",
  "Autumn-winter crop >150 days"    = "Autumn-winter crop >150 days",
  "Second harvest"                   = "second harvest",
  "Full cycle (forage)"              = "full cycle",
  "1st cut"                          = "1st cut",
  "2nd cut or later"                 = "2nd cut or later"
)
# Previous-crop and source choices are English-canonical in the rebuilt
# tables: label == value (identity named vector).
.PREV_CROP_CHOICES <- c(
  "None"                             = "None",
  "Sugar beet"                       = "Sugar beet",
  "Winter cereals straw removal"     = "Winter cereals straw removal",
  "Winter cereals straw burial"      = "Winter cereals straw burial",
  "Rapeseed"                         = "Rapeseed",
  "Sunflower"                        = "Sunflower",
  "Maize stalks removed"             = "Maize stalks removed",
  "Maize stalks buried"              = "Maize stalks buried",
  "Alfalfa thinned"                  = "Alfalfa thinned",
  "Alfalfa in good conditions"       = "Alfalfa in good conditions",
  "Leaf vegetables"                  = "Leaf vegetables",
  "Potato"                           = "Potato",
  "Tomato and other vegetables"      = "Tomato and other vegetables",
  "Short meadow or clover"           = "Short meadow or clover",
  "Soybean"                          = "Soybean",
  "Sorghum"                          = "Sorghum",
  "Legume green manure"              = "Legume green manure",
  "Grain legume (pea, bean, chickpea, etc.)" =
    "Grain legume (pea, bean, chickpea, etc.)",
  "Undefined"                        = "Undefined")

# N_balance() expects one of the four broad f.table categories, not the
# specific fertilizer product. Choose per-product applications at the
# Distribution plan step (plan_distribution()).
.SOURCE_CHOICES <- c(
  "None"                          = "None",
  "Cattle slurry"                  = "Cattle slurry",   # covers cattle + digestate
  "Pig slurry or poultry manure"  = "Pig slurry or poultry manure",
  "Manures"                        = "Manures")

.FERTORG_CHOICES <- c(
  "every year"       = "every year",
  "every 2 years"    = "every 2 years",
  "every 3 years"    = "every 3 years",
  "occasional"       = "occasional")

.LOCATION_CHOICES <- c(
  "Plain adjacent to urbanized areas" = "Plain adjacent to urbanized areas",
  "Isolated plain"                     = "Isolated plain",
  "Hill or mountain"                   = "Hill or mountain")
# ca.table$availability accepts Slow / Normal / Fast (drainage speed =
# oxygen availability proxy).
.O2_CHOICES <- c("Slow (poorly drained)" = "Slow",
                 "Normal"                 = "Normal",
                 "Fast (well drained)"    = "Fast")

# English crops supported by crop_params_NNI()
.NNI_CROP_CHOICES <- c(
  "Wheat"     = "wheat",
  "Maize"     = "maize",
  "Rice"      = "rice",
  "Barley"    = "barley",
  "Rapeseed"  = "rapeseed",
  "Sorghum"   = "sorghum",
  "Sunflower" = "sunflower",
  "Soybean"   = "soybean")

.agrinutri_fmt <- function(x, digits = 1) {
  if (is.null(x) || length(x) == 0 || !is.finite(x)) "--"
  else format(round(x, digits), big.mark = " ", scientific = FALSE)
}

.agrinutri_download_csv <- function(outputId, df_reactive, filename_prefix) {
  downloadHandler(
    filename = function()
      sprintf("%s_%s.csv", filename_prefix, format(Sys.time(), "%Y%m%d_%H%M")),
    content = function(file) {
      df <- df_reactive()
      if (is.null(df)) df <- data.frame()
      utils::write.csv(df, file, row.names = FALSE)
    }
  )
}

.agrinutri_card <- function(...) div(class = "agrinutri-card", ...)
.agrinutri_research_box <- function(...) div(class = "agrinutri-research-box", ...)

# --- Shared plot helpers ---------------------------------------------
source("helpers_plots.R", local = TRUE)

# --- Source modules ---------------------------------------------------
source("modules/welcome.R",   local = TRUE)
source("modules/nbalance.R",  local = TRUE)
source("modules/pkbalance.R", local = TRUE)
source("modules/plan.R",      local = TRUE)
source("modules/precision.R", local = TRUE)
source("modules/spatial.R",   local = TRUE)
source("modules/farm.R",      local = TRUE)
