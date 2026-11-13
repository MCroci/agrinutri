#' Nitrogen Provided by Organic Fertilization
#'
#' Calculates the amount of nitrogen (N) supplied to the soil through organic
#' fertilization. Optionally applies **DPI efficiency** by material type, soil
#' \code{distribution_efficiency} are both given). If either is \code{NULL}, falls back to
#' \code{f.table}: \code{value * quantity / 100}. Function \code{\link{N_balance}()} passes
#' computed soil texture and defaults distribution to \code{"medium"} so \code{Forg} matches
#' the DPI path used by Fert_Office (\emph{Apporti al terreno}). In the balance formula the term
#' to subtract is the **efficient N** (N utile) available to the crop in the
#' year of application, not total N (DPI Guida / FertDPI).
#'
#' @param source The source of organic fertilizer (e.g., "Cattle slurry", "Composted manure").
#' @param frequency The frequency of application (e.g., "every year", "every two years").
#' @param quantity The amount of organic fertilizer applied per application (in m3/ha cubic metres, or t/ha).
#'   Use \code{0} for no organic application (returns 0 kg N/ha).
#' @param soil_group Optional. Soil group from \code{calc_soil_group_and_id_rag()}
#'   (e.g. "Sandy textures", "Franco") to use DPI efficiency by texture. If \code{NULL},
#'   efficiency is taken from \code{f.table} (no texture/distribution).
#' @param distribution_efficiency Optional. \code{"efficient"}, \code{"medium"}, or \code{"low"}
#'   (DPI: Alta/Media/Bassa). Required together with \code{soil_group} for the DPI efficiency path.
#' @param f.table A data frame with columns \code{source}, \code{frequency}, \code{value}.
#'   Used when \code{soil_group} is \code{NULL}. Default is \code{agrinutri::f.table}.
#'
#' @return The estimated amount of nitrogen (N) in kg/ha available to the crop
#'   (efficient N when \code{soil_group} and \code{distribution_efficiency} are set).
#'
#' @references
#' DPI Emilia-Romagna, Guida alla fertilizzazione; efficienza in funzione di
#' tipologia di effluente, tessitura e modalita di distribuzione (Tabella 7 Norme Generali).
#'
#' @export
#' @examples
#' organic_fertilization(source = "Cattle slurry", frequency = "every year", quantity = 50)
#' organic_fertilization("Cattle slurry", "every year", 80,
#'   soil_group = "Sandy textures", distribution_efficiency = "efficient")
organic_fertilization <- function(source = "Cattle slurry", frequency = "every year",
                                  quantity = 100, soil_group = NULL,
                                  distribution_efficiency = NULL,
                                  f.table = agrinutri_data_get("f.table")) {

  if (quantity < 0) {
    stop("Quantity of organic fertilizer cannot be negative.")
  }
  if (quantity == 0) {
    return(0)
  }

  use_dpi_efficiency <- !is.null(soil_group) && !is.null(distribution_efficiency)

  if (use_dpi_efficiency) {
    # DPI: N utile = (N tot. nel fertilizzante × quantità) × Efficienza% / 100
    n_content <- .organic_N_content(source)
    if (is.na(n_content$N_per_unit)) {
      warning("Source '", source, "' not in DPI N-content table; falling back to f.table.")
      use_dpi_efficiency <- FALSE
    } else {
      N_total <- n_content$N_per_unit * quantity
      eff <- organic_N_efficiency(source, soil_group, distribution_efficiency)
      if (is.na(eff)) {
        warning("Efficiency not found for source/soil/distribution; falling back to f.table.")
        use_dpi_efficiency <- FALSE
      } else {
        return(N_total * eff)
      }
    }
  }

  if (!use_dpi_efficiency) {
    if (!source %in% f.table$source) {
      stop("Organic fertilizer source '", source, "' not found in the table.")
    }
    if (!frequency %in% f.table$frequency) {
      stop("Frequency '", frequency, "' not found in the table.")
    }
    factor <- f.table$value[f.table$source == source & f.table$frequency == frequency]
    if (is.na(factor)) {
      stop("No factor found for source '", source, "' and frequency '", frequency, "'.")
    }
    return(factor * quantity / 100)
  }
}

#' Typical N content (kg N per m³ or per t) by source, DPI/Guida
#' @noRd
.organic_N_content <- function(source) {
  tab <- .organic_N_content_table()
  source <- as.character(source)
  i <- match(source, tab$source)
  if (is.na(i)) {
    # Map DPI/Italian names to table entries
    alias <- c("Liquame bovino" = "Cattle slurry", "Liquame suino" = "Pig slurry",
               "Ammendante compostato" = "Composted manure")
    if (source %in% names(alias)) i <- match(alias[source], tab$source)
  }
  if (is.na(i)) return(list(N_per_unit = NA_real_, unit = NA_character_))
  list(N_per_unit = tab$N_per_unit[i], unit = tab$unit[i])
}

.organic_N_content_table <- function() {
  data.frame(
    source = c(
      "Liquame bovino", "Cattle slurry", "Liquame suino", "Pig slurry",
      "Liquame avicolo", "Digestato tal quale bovini", "Digestato tal quale suini",
      "Digestato tal quale avicoli", "Digestato frazione chiarificata",
      "Fanghi agroalimentari", "Ammendante compostato", "Composted manure",
      "Letame bovino", "Digestato palabile"
    ),
    N_per_unit = c(
      4.5, 4.5, 3.2, 3.2, 12, 4.5, 3.2, 12, 8, 2.8, 18, 18, 5, 4
    ),
    unit = c(
      "m3", "m3", "m3", "m3", "m3", "m3", "m3", "m3", "m3", "t", "t", "t", "t", "t"
    ),
    stringsAsFactors = FALSE
  )
}
