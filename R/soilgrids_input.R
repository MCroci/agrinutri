#' Build an NFert soil input stack from SoilGrids (open global default)
#'
#' Downloads the soil properties that the NFert nitrogen balance consumes from
#' the ISRIC SoilGrids 2.0 service and returns them as a \code{terra::SpatRaster}
#' with the layer names, units and shape that \code{\link{spatial_N_balance}()}
#' and \code{\link{farm_balance}()} expect. It is the open, global fallback soil
#' layer: with it the whole NFert pipeline (balance, prescription mean and
#' uncertainty) runs end to end on freely licensed data (CC-BY 4.0) anywhere on
#' Earth, without a proprietary local soil map.
#'
#' SoilGrids is a 250 m global product with modest local accuracy (global
#' cross-validation model efficiency about 0.5 for total nitrogen and 0.65 for
#' organic carbon), so it drives the field-mean regulatory dose and the farm
#' total, not the within-field 10 m pattern. Treat it as an open default and a
#' benchmark for the value of local sampling, not as a validated field input.
#'
#' Unit conversions applied to the raw SoilGrids values (as returned by
#' \code{geodata}): clay and sand from g/kg to percent (divide by 10); total
#' nitrogen from cg/kg to g/kg (divide by 100); organic carbon from dg/kg to
#' g/kg (divide by 10); soil organic matter as organic-carbon percent times
#' 1.724; the carbon-to-nitrogen ratio as organic carbon over total nitrogen
#' (both in g/kg).
#'
#' @param aoi Area of interest: an \code{sf}/\code{sfc} object, a
#'   \code{terra::SpatVector}, or a path to a vector file readable by
#'   \code{terra::vect}. Its extent (buffered) is downloaded.
#' @param depths Character vector of SoilGrids depth intervals to combine into a
#'   thickness-weighted topsoil value. Defaults to the 0 to 30 cm topsoil
#'   (\code{c("0-5", "5-15", "15-30")}). Accepted: "0-5", "5-15", "15-30",
#'   "30-60", "60-100", "100-200".
#' @param crs_out Target coordinate reference system for the returned stack
#'   (anything \code{terra::crs} accepts). Defaults to the CRS of \code{aoi}
#'   (or of \code{template} when supplied).
#' @param template Optional \code{terra::SpatRaster} whose grid the output is
#'   resampled to (for alignment with a field raster). Note that resampling a
#'   250 m product to a finer grid does not add spatial detail.
#' @param uncertainty Logical; if \code{TRUE}, also download the Q0.05 and Q0.95
#'   quantiles and append per-property standard-deviation layers
#'   (\code{Clay_sd, Sand_sd, TN_sd, SOM_sd}, approximated as
#'   (Q0.95 - Q0.05) / 3.29 in converted units) for use as the input error of a
#'   Monte-Carlo propagation.
#' @param buffer Numeric buffer (in metres) added around the AOI extent before
#'   cropping, so edge pixels are not lost. Default 500.
#'
#' @return A \code{terra::SpatRaster} with layers \code{TN} (g/kg), \code{SOM}
#'   (percent), \code{Clay} (percent), \code{Sand} (percent) and \code{CNratio}
#'   (dimensionless), masked to \code{aoi} and in \code{crs_out}; plus the four
#'   \code{*_sd} layers when \code{uncertainty = TRUE}. The result is ready to
#'   pass as the \code{soil_stack} argument of \code{\link{spatial_N_balance}()}.
#'
#' @section Attribution:
#' SoilGrids data are released under CC-BY 4.0. Cite Poggio et al. (2021),
#' SoilGrids 2.0, SOIL 7, 217-240, \doi{10.5194/soil-7-217-2021}.
#'
#' @seealso \code{\link{spatial_N_balance}}, \code{\link{farm_balance}}
#'
#' @examplesIf requireNamespace("geodata", quietly = TRUE) && interactive()
#' aoi <- sf::st_read(system.file("extdata/aoi.geojson", package = "NFert"))
#' soil <- soilgrids_input(aoi, crs_out = 32632)
#' n <- spatial_N_balance(soil, expected_yield_tons_ha = 9,
#'                        crop = "Grano tenero FF (granella)",
#'                        ccp = "Spring-summer crop 100-130 days",
#'                        winter_rain = 150, start_spring_rain = 0,
#'                        prev_crop = "Maize stalks buried")
#' @export
soilgrids_input <- function(aoi,
                            depths = c("0-5", "5-15", "15-30"),
                            crs_out = NULL,
                            template = NULL,
                            uncertainty = FALSE,
                            buffer = 500) {

  if (!requireNamespace("geodata", quietly = TRUE))
    stop("soilgrids_input() needs the 'geodata' package. Install it with ",
         "install.packages('geodata').", call. = FALSE)

  # --- resolve the AOI to a SpatVector --------------------------------------
  av <- .sg_as_vect(aoi)
  if (is.null(crs_out)) {
    crs_out <- if (!is.null(template)) terra::crs(template) else terra::crs(av)
  }
  if (is.numeric(crs_out)) crs_out <- paste0("EPSG:", crs_out)

  # --- depth intervals -> SoilGrids depth code + thickness weight ------------
  depth_tbl <- c("0-5" = 5, "5-15" = 15, "15-30" = 30, "30-60" = 60,
                 "60-100" = 100, "100-200" = 200)
  thick_tbl <- c("0-5" = 5, "5-15" = 10, "15-30" = 15, "30-60" = 30,
                 "60-100" = 40, "100-200" = 100)
  bad <- setdiff(depths, names(depth_tbl))
  if (length(bad))
    stop("Unknown depth interval(s): ", paste(bad, collapse = ", "),
         ". Accepted: ", paste(names(depth_tbl), collapse = ", "), call. = FALSE)
  dcodes <- depth_tbl[depths]
  weights <- thick_tbl[depths]; weights <- weights / sum(weights)

  vars <- c(clay = "clay", sand = "sand", nitrogen = "nitrogen", soc = "soc")
  stats <- if (uncertainty) c("mean", "Q0.05", "Q0.95") else "mean"

  # --- pull, crop and thickness-average each (var, stat) ---------------------
  grab <- function(v, st) {
    acc <- NULL
    for (i in seq_along(dcodes)) {
      r <- tryCatch(
        geodata::soil_world_vsi(var = v, depth = as.integer(dcodes[i]), stat = st),
        error = function(e)
          stop("SoilGrids download failed for ", v, " ", names(dcodes)[i],
               " ", st, " (check the internet connection): ",
               conditionMessage(e), call. = FALSE))
      avp <- terra::project(av, terra::crs(r))
      rc  <- terra::crop(r, terra::ext(avp) + buffer, snap = "out")
      layer <- rc * weights[i]
      acc <- if (is.null(acc)) layer else acc + layer
    }
    names(acc) <- paste0(v, "_", st)
    acc
  }

  raw <- list()
  for (v in vars) for (st in stats) raw[[paste0(v, "_", st)]] <- grab(v, st)

  # --- convert raw SoilGrids units to NFert balance units --------------------
  # clay/sand g/kg -> %, nitrogen cg/kg -> g/kg, soc dg/kg -> g/kg
  conv <- function(tag) {
    clay <- raw[[paste0("clay_", tag)]] / 10
    sand <- raw[[paste0("sand_", tag)]] / 10
    tn   <- raw[[paste0("nitrogen_", tag)]] / 100          # g/kg
    soc  <- raw[[paste0("soc_", tag)]] / 10                # g/kg
    som  <- (soc / 10) * 1.724                             # SOM %
    cn   <- soc / tn                                       # C/N
    out  <- c(tn, som, clay, sand, cn)
    names(out) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
    out
  }
  stack <- conv("mean")

  # --- optional per-property SD from the 5-95 quantile range -----------------
  if (uncertainty) {
    z <- stats::qnorm(0.95) - stats::qnorm(0.05)           # ~3.29
    sd_of <- function(v, scale) (raw[[paste0(v, "_Q0.95")]] -
                                   raw[[paste0(v, "_Q0.05")]]) / z * scale
    clay_sd <- sd_of("clay", 1 / 10)
    sand_sd <- sd_of("sand", 1 / 10)
    tn_sd   <- sd_of("nitrogen", 1 / 100)
    som_sd  <- sd_of("soc", (1 / 10) / 10 * 1.724)
    sds <- c(clay_sd, sand_sd, tn_sd, som_sd)
    names(sds) <- c("Clay_sd", "Sand_sd", "TN_sd", "SOM_sd")
    stack <- c(stack, sds)
  }

  # --- reproject / align / mask ---------------------------------------------
  if (!is.null(template)) {
    stack <- terra::project(stack, template, method = "bilinear")
  } else if (!terra::same.crs(stack, crs_out)) {
    stack <- terra::project(stack, crs_out, method = "bilinear")
  }
  av_out <- terra::project(av, terra::crs(stack))
  stack <- terra::mask(terra::crop(stack, av_out, snap = "out"), av_out)

  message("SoilGrids 2.0 input over ", length(depths),
          " depth interval(s) [", paste(depths, collapse = ", "),
          "] at ~250 m. Source: Poggio et al. (2021), CC-BY 4.0. ",
          "This is a global default; it drives the field-mean and farm totals, ",
          "not the within-field pattern.")
  stack
}

# Coerce an sf / SpatVector / file path to a terra SpatVector.
.sg_as_vect <- function(aoi) {
  if (inherits(aoi, "SpatVector")) return(aoi)
  if (inherits(aoi, c("sf", "sfc"))) return(terra::vect(aoi))
  if (is.character(aoi) && length(aoi) == 1L && file.exists(aoi))
    return(terra::vect(aoi))
  stop("`aoi` must be an sf/sfc object, a terra SpatVector, or a path to a ",
       "readable vector file.", call. = FALSE)
}
