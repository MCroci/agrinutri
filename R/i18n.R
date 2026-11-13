#' English alias dictionaries for the agrinutri reference tables
#'
#' Starting with agrinutri 0.12.0 every bundled reference table
#' (\code{uptake_table}, \code{mas.table}, \code{e.table},
#' \code{organic_fertilizers.table}, \code{cycle_modality.table},
#' \code{distribution_modalities.table}, ...) uses the English name as
#' the canonical lookup column. The Italian name of each row is still
#' kept in a secondary \code{*_it} column so that legacy scripts can be
#' re-used with a single translation step.
#'
#' The dictionaries below survive from the transitional 0.11 release and
#' are now a convenience for users who still want to pass Italian
#' strings: \code{\link{agrinutri_en2it}()} and \code{\link{agrinutri_it2en}()}
#' translate either direction. Most code bases do not need to call them
#' any longer - the tables accept English strings natively.
#'
#' Five dictionaries are exported:
#' \code{crop_en2it}, \code{prev_crop_en2it}, \code{source_en2it},
#' \code{modality_epoch_en2it} and \code{level_en2it}. The helpers
#' \code{agrinutri_translate()} and \code{agrinutri_en2it()} take an English
#' string (or a vector) and return the corresponding Italian canonical
#' string, falling back to the input unchanged when no match is found.
#'
#' @section Adding new aliases:
#' The dictionaries are plain named character vectors. Extending them in
#' user code is a matter of \code{c(agrinutri::crop_en2it, "My Crop" = "Mia
#' coltura")}. The helpers match case-insensitively so users don't need
#' to worry about capitalisation.
#'
#' @name i18n
NULL

# ---- Dictionaries ---------------------------------------------------
# All names are English aliases; all values are the exact Italian strings
# found in the corresponding agrinutri reference table.

#' @rdname i18n
#' @export
crop_en2it <- c(
  # --- Cereals --------------------------------------------------------
  "Silage maize (class 700)"       = "Mais trinciato classe 700",
  "Silage maize (class 500)"       = "Mais trinciato classe 500",
  "Grain maize 500-700"            = "Mais da granella 500-700 (granella)",
  "Grain maize 500-700 (whole)"    = "Mais da granella 500-700 (pianta intera)",
  "Grain maize 300-400"            = "Mais da granella 300-400 (granella)",
  "Grain maize 300-400 (whole)"    = "Mais da granella 300-400 (pianta intera)",
  "Sweet maize"                    = "Mais dolce  (spighe)",
  "Sweet maize (whole)"            = "Mais dolce (pianta intera)",
  "Soft wheat FF - strong (grain)"    = "Grano tenero FF (granella)",
  "Soft wheat FF - strong (whole plant)" = "Grano tenero FF (pianta intera)",
  "Soft wheat FP/FPS"              = "Grano tenero FP/FPS (granella)",
  "Soft wheat FP/FPS (whole)"      = "Grano tenero FP/FPS (pianta intera)",
  "Biscuit wheat"                  = "Grano tenero biscottiero  (granella)",
  "Biscuit wheat (whole)"          = "Grano tenero biscottiero pianta intera",
  "Durum wheat"                    = "Grano duro (granella)",
  "Durum wheat (whole)"            = "Grano duro (pianta intera)",
  "Soft wheat silage"              = "Grano tenero  insilato",
  "Durum wheat silage"             = "Grano duro  insilato",
  "Barley"                         = "Orzo (granella)",
  "Barley (whole)"                 = "Orzo (pianta intera)",
  "Barley silage"                  = "Orzo insilato",
  "Rice"                           = "Riso (granella)",
  "Rice (grain+straw)"             = "Riso (granella+paglia)",
  "Sorghum - grain"                = "Sorgo da granella  (solo granella)",
  "Sorghum - grain (whole)"        = "Sorgo da granella (pianta intera)",
  "Sorghum - forage"               = "Sorgo da foraggio",
  # --- Industrials ----------------------------------------------------
  "Soybean"                        = "Soia (granella)",
  "Soybean (whole)"                = "Soia (pianta intera)",
  "Sunflower"                      = "Girasole (acheni)",
  "Sunflower (whole)"              = "Girasole (pianta intera)",
  "Rapeseed"                       = "Colza",
  "Rapeseed (whole)"               = "Colza pianta intera",
  "Rapeseed silage"                = "Colza insilato",
  "Sugar beet"                     = "Barbabietola da zucchero  (radici)",
  # --- Forages and meadows -------------------------------------------
  "Alfalfa"                        = "Erba medica",
  "Orchardgrass"                   = "Erba mazzolina",
  "Autumn-spring cereal/crucifer grass" = "Erbai aut prim. Di cer. O cruc.",
  "Autumn-spring legume grass"          = "Erbai aut prim. Di leguminose",
  "Biennial or grass-meadow"            = "Erbai biennali o Prati avv. di Graminacee",
  "Biennial mixed or polyphytic meadow" = "Erbai biennali misti o Prati avv. Polifita",
  # --- Vegetables -----------------------------------------------------
  "Potato"                            = "Patata",
  "Processing tomato (medium yield)"  = "Pomodoro da industria media produzione",
  "Processing tomato (high yield)"    = "Pomodoro da industria alta produzione",
  "Fresh-market tomato (field)"       = "Pomodoro da mensa a pieno campo",
  "Fresh-market tomato (greenhouse)"  = "Pomodoro da mensa in serra",
  # --- Seed production ------------------------------------------------
  "Alfalfa (seed)"                    = "Erba medica  da seme",
  "Durum wheat (seed)"                = "Frumento duro da seme (granella)",
  "Soft wheat (seed)"                 = "Frumento tenero da seme (granella)",
  "Sunflower (seed)"                  = "Girasole da seme (granella)",
  "Barley (seed)"                     = "Orzo da seme (granella)",
  "Soybean (seed)"                    = "Soia da seme (granella)",
  # --- Vineyards and orchards ----------------------------------------
  "Vineyard (plain)"    = "Vite per uva da vino (pianura) grappoli, legno e foglie",
  "Vineyard (hill/mountain)" = "Vite per uva da vino (collina e montagna) grappoli, tralci e foglie"
)

#' @rdname i18n
#' @export
prev_crop_en2it <- c(
  "Maize stalks removed"              = "Mais stocchi asportati",
  "Maize stalks incorporated"         = "Mais stocchi interrati",
  "Soybean"                            = "Soia",
  "Sorghum"                            = "Sorgo",
  "Sugar beet"                         = "Barbabietola",
  "Rapeseed"                           = "Colza",
  "Sunflower"                          = "Girasole",
  "Potato"                             = "Patata",
  "Tomato and other vegetables"        = "Pomodoro e altre orticole",
  "Alfalfa meadow (thinned)"           = "Medicaio diradato",
  "Alfalfa meadow (good condition)"    = "Medicaio in buone conndizioni"
)

#' @rdname i18n
#' @export
source_en2it <- c(
  "None"                   = NA_character_,
  "Beef cattle slurry"     = "liquami bovini da carne",
  "Dairy cattle slurry"    = "liquami bovini da latte",
  "Pig slurry"             = "liquami suini",
  "Layer hen slurry"       = "liquami ovaiole",
  "Cattle manure"          = "letame bovino",
  "Sheep manure"           = "letame ovino",
  "Pig manure"             = "letame suino",
  "Broiler litter"         = "lettiera esausta polli da carne",
  "Pre-dried poultry manure" = "pollina preessicata",
  "Digestate (biomass/cattle)" = "Digestato t.q. biomasse o con effl. bovini",
  "Digestate (pig)"        = "Digestato t.q. con prevalenza effl. Suini",
  "Digestate (poultry)"    = "Digestato t.q. con prevalenza di effl. avicoli",
  "Digestate (clarified)"  = "Digestato frazione chiarificata",
  "Digestate (solid)"      = "Digestato frazione palabile",
  "Composted mixed amendment" = "ammendante compostato misto",
  "Humofort pellet"        = "humofort pellet amm. Org. Nat.",
  "Humoscam pellet"        = "humoscam pellet amm. Veg. Fermentato",
  "Agri-food sludges"      = "fanghi agroalimentari",
  "Tioscam 50"             = "tioscam 50 amm. Base ferro e zolfo",
  # Common aliases used historically in the agrinutri code base
  "Cattle slurry"          = "liquami bovini da carne",
  "Digestate"              = "Digestato t.q. biomasse o con effl. bovini",
  "Farmyard manure"        = "letame bovino",
  "Composted manure"       = "ammendante compostato misto"
)

#' @rdname i18n
#' @export
modality_epoch_en2it <- c(
  "Pre-sowing"                       = "Presemina",
  "Bare soil, sown next year"        = "Su terreno nudo  e semina nell'anno successivo",
  "Straw residues, sown next year"   = "Su residui pagliosi e semina nell'anno successivo",
  "Straw residues, sown same year"   = "Su residui pagliosi e semina nel medesimo anno ",
  "At soil preparation, sown same year" = "Alla preparazione del terreno e semina nel medesimo anno",
  "Top-dress fertigation"            = "In copertura con fertirrigazione",
  "Top-dress low-pressure fertigation" = "In copertura con fertirrigazione a bassa pressione",
  "Top-dress with incorporation"     = "In copertura con interramento",
  "Top-dress spring no-incorporation" = "In copertura in primavera senza interramento",
  "Top-dress summer no-incorporation" = "In copertura in estate senza interramento",
  "Top-dress at full tillering (late winter)" = "In copertura nella fase di pieno accestimento (fine inverno)",
  "Top-dress at stem elongation"     = "In copertura nella fase di levata",
  "Late autumn (>15/10)"             = "Tardo autunno (>15/10)",
  "Spring regrowth and cuts"         = "Ripresa vegetativa e tagli primaverili",
  "Summer or early autumn cuts (<15/10)" = "Tagli estivi o autunno precoci (< 15/10)",
  "Pre-planting far from growth"     = "Preimpianto distante dalla crescita",
  "Pre-planting near growth"         = "Preimpianto vicino alla crescita"
)

#' @rdname i18n
#' @export
level_en2it <- c(
  "High efficiency"   = "alta",
  "Medium efficiency" = "media",
  "Low efficiency"    = "bassa"
)

# Reverse-lookups (IT -> EN) derived at load time.
.make_it2en <- function(d) {
  ok <- !is.na(d) & !is.na(names(d))
  stats::setNames(names(d)[ok], unname(d)[ok])
}

# ---- Translator functions ------------------------------------------

#' @noRd
.canonicalize_legacy_crop_en <- function(x) {
  short <- c(
    "soft wheat ff" = "Soft wheat FF - strong (grain)",
    "soft wheat ff (whole)" = "Soft wheat FF - strong (whole plant)"
  )
  for (i in seq_along(x)) {
    if (is.na(x[i]) || !nzchar(x[i])) next
    k <- tolower(trimws(as.character(x[i])))
    if (k %in% names(short)) x[i] <- unname(short[k])
  }
  x
}

#' Translate an English alias into its canonical Italian agrinutri key
#'
#' Case-insensitive lookup in one of the agrinutri translation dictionaries
#' (\code{\link{crop_en2it}}, \code{\link{prev_crop_en2it}},
#' \code{\link{source_en2it}}, \code{\link{modality_epoch_en2it}},
#' \code{\link{level_en2it}}). Falls back to the input unchanged when no
#' match is found, so strings that already happen to be in the Italian
#' canonical form pass through.
#'
#' @param x Character (or character vector) of English aliases to
#'   translate.
#' @param kind One of \code{"crop"}, \code{"prev_crop"}, \code{"source"},
#'   \code{"modality_epoch"}, \code{"level"}. Selects which dictionary
#'   to use.
#'
#' @return A character vector the same length as \code{x}.
#' @export
#' @examples
#' agrinutri_en2it("Silage maize (class 700)",  kind = "crop")
#' agrinutri_en2it("Maize stalks removed",       kind = "prev_crop")
#' agrinutri_en2it(c("Dairy cattle slurry", "None"), kind = "source")
agrinutri_en2it <- function(x, kind = c("crop", "prev_crop", "source",
                                    "modality_epoch", "level")) {
  kind <- match.arg(kind)
  dict <- switch(kind,
    crop           = crop_en2it,
    prev_crop      = prev_crop_en2it,
    source         = source_en2it,
    modality_epoch = modality_epoch_en2it,
    level          = level_en2it)
  if (is.null(x)) return(x)
  if (identical(kind, "crop")) x <- .canonicalize_legacy_crop_en(x)
  out <- character(length(x))
  lookup_names <- tolower(names(dict))
  for (i in seq_along(x)) {
    if (is.na(x[i]) || !nzchar(x[i])) { out[i] <- NA_character_; next }
    hit <- match(tolower(as.character(x[i])), lookup_names)
    out[i] <- if (!is.na(hit)) unname(dict[[hit]]) else as.character(x[i])
  }
  out
}

#' Translate an Italian agrinutri canonical key into its English alias
#' @param x Character vector of Italian canonical strings.
#' @param kind One of \code{"crop"}, \code{"prev_crop"}, \code{"source"},
#'   \code{"modality_epoch"}, \code{"level"}.
#' @return A character vector of English aliases.
#' @export
#' @examples
#' agrinutri_it2en("Mais trinciato classe 700", kind = "crop")
agrinutri_it2en <- function(x, kind = c("crop", "prev_crop", "source",
                                    "modality_epoch", "level")) {
  kind <- match.arg(kind)
  dict <- switch(kind,
    crop           = .make_it2en(crop_en2it),
    prev_crop      = .make_it2en(prev_crop_en2it),
    source         = .make_it2en(source_en2it),
    modality_epoch = .make_it2en(modality_epoch_en2it),
    level          = .make_it2en(level_en2it))
  if (is.null(x)) return(x)
  out <- character(length(x))
  for (i in seq_along(x)) {
    if (is.na(x[i]) || !nzchar(x[i])) { out[i] <- NA_character_; next }
    hit <- match(as.character(x[i]), names(dict))
    out[i] <- if (!is.na(hit)) unname(dict[[hit]]) else as.character(x[i])
  }
  out
}
