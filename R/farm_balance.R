#' Apply the agrinutri balance to every plot of a farm
#'
#' Reads a vector layer (GeoJSON, Shapefile, GeoPackage, or an in-memory
#' \code{sf} object) in which each feature is an agronomic plot, runs
#' \code{\link{N_balance}} on every feature using the attributes as
#' arguments, and returns an enriched \code{sf} object with the
#' field-scale target N* (\code{N_target}, kg N ha\eqn{^{-1}}), the crop-
#' specific MAS cap, a compliance flag and the total N (kg) required by
#' each plot (\code{N_total_kg = N_target * area_ha}). The enriched layer
#' can be written back to disk as GeoJSON or any other OGR format.
#'
#' @section Expected attribute columns:
#' Every feature must carry at least:
#' \tabular{lll}{
#' \strong{Column} \tab \strong{Example} \tab \strong{Notes} \cr
#' \code{crop} \tab "Mais da insilato (classe 700)" \tab DPI 2026 name \cr
#' \code{expected_yield_tons_ha} \tab 60 \tab target yield \cr
#' \code{ccp} \tab "Spring-summer crop 100-130 days" \tab climate period \cr
#' \code{sand}, \code{clay} \tab 50, 35 \tab pct of texture \cr
#' \code{Ntot}, \code{SOM}, \code{CN} \tab 1.2, 1.2, 9.5 \tab soil analysis \cr
#' \code{oxygen_availability} \tab "Normal" / "Low" / "High" \tab \cr
#' \code{winter_rain}, \code{start_spring_rain} \tab 160, 40 \tab mm \cr
#' \code{prev_crop} \tab "Winter cereals straw removal" \tab \cr
#' \code{source} \tab "Cattle slurry" or "None"/NA \tab organic source \cr
#' \code{fertorg_frequency} \tab "every year" \tab \cr
#' \code{location} \tab "Plain adjacent to urbanized areas" \tab \cr
#' \code{forg_quantity} \tab 100 \tab organic dose this year (m\eqn{^3}/ha or t/ha, see \code{\link{N_balance}}) \cr
#' \code{organic_previous_year_N} \tab 50 \tab optional; kg N ha\eqn{^{-1}} from organic applied last year (term \code{F}) \cr
#' \code{area_ha} \tab 5.2 \tab used to derive \code{N_total_kg}
#' }
#' Italian aliases (Frumento tenero, Liquame bovino, Cereali vernini -
#' paglia asportata, ...) are accepted because the underlying agrinutri
#' functions carry the translation layer.
#'
#' @section Output columns added to the layer:
#' \describe{
#'   \item{\code{N_target}}{Net mineral N to apply (kg N ha\eqn{^{-1}}).}
#'   \item{\code{MAS_cap}}{Crop-specific maximum allowed dose.}
#'   \item{\code{MAS_ok}}{Logical - \code{N_target <= MAS_cap}.}
#'   \item{\code{N_total_kg}}{\code{N_target * area_ha} (kg N for the plot).}
#'   \item{\code{balance_error}}{\code{NA} on success, error message
#'     otherwise (rows that fail are not dropped).}
#' }
#'
#' @param x Either a path to a file readable by \code{\link[sf]{st_read}}
#'   (GeoJSON, Shapefile, GeoPackage, ...) or a pre-loaded \code{sf} object.
#' @param p_balance Logical. If \code{TRUE} also run \code{\link{P_balance}}
#'   per plot, using the columns \code{olsen_value} (ppm) and
#'   \code{olsen_unit} (default \code{"P2O5"}). Adds \code{P2O5_target}
#'   and \code{P2O5_total_kg}.
#' @param k_balance Logical. Same for \code{\link{K_balance}}, with
#'   columns \code{k_value} (ppm) and \code{k_unit} (default \code{"K2O"}).
#' @param output Optional path where to write the enriched layer (the
#'   extension determines the driver used by \code{\link[sf]{st_write}};
#'   \code{.geojson} is a common choice).
#' @param quiet Logical, passed to \code{\link[sf]{st_read}} and
#'   \code{\link[sf]{st_write}}.
#'
#' @return The enriched \code{sf} object. If \code{output} is given, the
#'   file is also written to disk (existing files are overwritten).
#'
#' @seealso \code{\link{N_balance}}, \code{\link{P_balance}},
#'   \code{\link{K_balance}}, \code{\link{plan_distribution}}
#'
#' @examples
#' \dontrun{
#' ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
#' farm <- farm_balance(ex)
#' print(farm[, c("plot_id", "crop", "area_ha",
#'                 "N_target", "MAS_cap", "N_total_kg")])
#'
#' # Write the enriched layer for GIS use:
#' farm_balance(ex, output = "my_farm_with_Ntargets.geojson")
#' }
#' @export
farm_balance <- function(x,
                         p_balance = FALSE,
                         k_balance = FALSE,
                         output    = NULL,
                         quiet     = TRUE) {
  if (!requireNamespace("sf", quietly = TRUE))
    stop("Package 'sf' is required for farm_balance().")

  if (is.character(x) && length(x) == 1) {
    farm <- sf::st_read(x, quiet = quiet)
  } else if (inherits(x, "sf")) {
    farm <- x
  } else {
    stop("`x` must be a path to a vector file or an sf object.")
  }

  required <- c("crop", "expected_yield_tons_ha", "ccp",
                "sand", "clay", "Ntot", "SOM", "CN",
                "oxygen_availability", "winter_rain", "start_spring_rain",
                "prev_crop", "fertorg_frequency", "location")
  missing_cols <- setdiff(required, names(farm))
  if (length(missing_cols) > 0)
    stop("Missing required columns: ",
         paste(missing_cols, collapse = ", "))

  n_feat <- nrow(farm)
  N_target     <- rep(NA_real_, n_feat)
  MAS_cap      <- rep(NA_real_, n_feat)
  balance_err  <- rep(NA_character_, n_feat)
  P_target     <- rep(NA_real_, n_feat)
  K_target     <- rep(NA_real_, n_feat)

  # Robust scalar extractor: NA on NULL / zero-length / non-numeric.
  as_scalar_num <- function(x) {
    if (is.null(x) || length(x) == 0) return(NA_real_)
    suppressWarnings(as.numeric(x)[1])
  }
  # get_MAS() can return NULL with a warning when the crop is missing
  # from mas.table - wrap it so failures become NA rather than crashes.
  get_mas_safe <- function(crop) {
    out <- tryCatch(
      suppressWarnings(get_MAS(crop = crop)),
      error = function(e) NULL)
    if (is.null(out)) return(NA_real_)
    as_scalar_num(out$mas_N)
  }

  for (i in seq_len(n_feat)) {
    row <- farm[i, , drop = TRUE]
    # Reference tables are English-canonical since agrinutri 0.12.0, so no
    # translation is needed for ordinary input. Legacy Italian strings
    # are still accepted: they are routed through agrinutri_it2en() then
    # ignored if the English lookup succeeds.
    coerce_en <- function(x, kind)
      if (is.null(x) || length(x) == 0 || is.na(x)) NA_character_
      else {
        xen <- suppressWarnings(agrinutri_it2en(as.character(x), kind = kind))
        # agrinutri_it2en returns the input unchanged when no alias match
        # is found, so we simply keep whatever we get.
        xen
      }
    args_N <- list(
      crop                   = coerce_en(row$crop,      "crop"),
      expected_yield_tons_ha = as.numeric(row$expected_yield_tons_ha),
      ccp                    = as.character(row$ccp),
      sand                   = as.numeric(row$sand),
      clay                   = as.numeric(row$clay),
      Ntot                   = as.numeric(row$Ntot),
      SOM                    = as.numeric(row$SOM),
      CN                     = as.numeric(row$CN),
      oxygen_availability    = agrinutri_normalize_oxygen(
        as.character(row$oxygen_availability %||% "Normal")
      ),
      winter_rain            = as.numeric(row$winter_rain),
      start_spring_rain      = as.numeric(row$start_spring_rain),
      prev_crop              = coerce_en(row$prev_crop, "prev_crop"),
      fertorg_frequency      = as.character(row$fertorg_frequency),
      location               = as.character(row$location),
      source = {
        s <- as.character(row$source %||% NA)
        if (is.na(s) || identical(tolower(s), "none") ||
            identical(tolower(s), "nessuno")) NA
        else coerce_en(s, "source")
      },
      forg_quantity = as.numeric(row$forg_quantity %||% 0),
      organic_previous_year_N = as.numeric(row$organic_previous_year_N %||% 0)
    )
    res <- tryCatch({
      bal <- do.call(N_balance, args_N)
      list(
        N   = as_scalar_num(calculate_N_fertilization(bal)),
        MAS = get_mas_safe(args_N$crop)
      )
    },
    error = function(e) {
      balance_err[i] <<- conditionMessage(e)
      list(N = NA_real_, MAS = NA_real_)
    })
    N_target[i] <- res$N
    MAS_cap[i]  <- res$MAS

    if (isTRUE(p_balance) &&
        !is.null(row$olsen_value) && is.finite(row$olsen_value)) {
      P_target[i] <- tryCatch({
        p <- P_balance(
          crop                   = args_N$crop,
          expected_yield_tons_ha = args_N$expected_yield_tons_ha,
          olsen_value            = as.numeric(row$olsen_value),
          olsen_unit             = as.character(row$olsen_unit %||% "P2O5"),
          sand = args_N$sand, clay = args_N$clay)
        p$P2O5_required %||% NA_real_
      }, error = function(e) NA_real_)
    }
    if (isTRUE(k_balance) &&
        !is.null(row$k_value) && is.finite(row$k_value)) {
      K_target[i] <- tryCatch({
        k <- K_balance(
          crop                   = args_N$crop,
          expected_yield_tons_ha = args_N$expected_yield_tons_ha,
          k_value                = as.numeric(row$k_value),
          k_unit                 = as.character(row$k_unit %||% "K2O"),
          sand = args_N$sand, clay = args_N$clay)
        k$K2O_required %||% NA_real_
      }, error = function(e) NA_real_)
    }
  }

  farm$N_target <- round(N_target, 1)
  farm$MAS_cap  <- round(MAS_cap, 1)
  farm$MAS_ok   <- is.finite(farm$N_target) & is.finite(farm$MAS_cap) &
                    (farm$N_target <= farm$MAS_cap)
  if ("area_ha" %in% names(farm))
    farm$N_total_kg <- round(farm$N_target * as.numeric(farm$area_ha), 1)
  if (isTRUE(p_balance)) farm$P2O5_target <- round(P_target, 1)
  if (isTRUE(k_balance)) farm$K2O_target  <- round(K_target, 1)
  farm$balance_error <- balance_err

  if (!is.null(output)) {
    if (file.exists(output)) file.remove(output)
    sf::st_write(farm, output, quiet = quiet, delete_dsn = TRUE)
  }
  farm
}

# Internal helper: NULL-coalescing operator (also used by other R files).
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
