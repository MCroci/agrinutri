#' agrinutri Package Data
#'
#' Internal datasets used by the agrinutri package for nitrogen (and, from v0.2.0,
#' phosphorus and potassium) balance calculations following the Disciplinari di
#' Produzione Integrata (DPI) Emilia-Romagna (Allegato 2 - metodo del bilancio,
#' Allegati 3, 4, 6, 7, 9) and the FertDPI / Fert_Office reference tool
#' (v1.26, Febbraio 2026).
#'
#' @name agrinutri-data
#' @aliases uptake_table e.table f.table g.table soil.table tri2.table tri3.table
#'          ca.table cb.table coefN_readily coefN_mineralised coef_time s2.rast
#'          mas.table crops.table crop_groups.table texture_groups.table so.table
#'          so_max_input ph.table total_carbonate.table active_carbonate.table
#'          p_availability.table p_availability_meta k_availability.table fertilizer_types.table organic_fertilizers.table
#'          efficiency.table distribution_modalities.table cycle_modality.table
#'          cycles.table cycle_phases.table c_d.table
#'          standard_pk_doses.table standard_decrements.table
#'          standard_increments.table standard_multicycle.table
#'          mineral_fertilizers.table
#'
#' @details
#' These datasets are loaded automatically with the package using `LazyData: true`
#' in the DESCRIPTION file. Soil texture is grouped in three DPI classes:
#' (1) Tendenzialmente sabbioso (S, SF, FS), (2) Franco / Medio impasto
#' (L, F, FL, FSA, FA), (3) Tendenzialmente argilloso (FLA, AS, AL, A).
#' Tables with character keys retain the original Italian naming used in
#' Fert_Office; English aliases (`*_it` columns, or English primary values)
#' are provided where backward compatibility with earlier agrinutri versions is
#' required.
#'
#' @section Core N datasets:
#' \describe{
#'   \item{uptake_table}{Crop unit absorption/asportation coefficients for
#'         N, P2O5 and K2O (from foglio `A`). 247 crops in v0.2.0.}
#'   \item{e.table}{Precessione: N kg/ha from previous crop residues, with
#'         legume flag and Italian alias.}
#'   \item{f.table}{Coefficients of recovery for organic fertilisation applied
#'         in previous years (4 matrici x 4 frequenze = 16 rows).}
#'   \item{g.table}{Annual N deposition (kg/ha) per location (3 rows).}
#'   \item{soil.table}{USDA 12 soil classes mapped to DPI 3-group (ID_Rag).}
#'   \item{tri2.table}{USDA soil texture triangle lookup (ID_Rag by clay/sand).}
#'   \item{tri3.table}{Simplified USDA soil texture triangle lookup.}
#'   \item{ca.table}{Oxygen availability -> ID_Dre mapping.}
#'   \item{cb.table}{Leaching C (kg/ha) and immobilization factor `fc_D` by
#'         ID_Rag x ID_Dre.}
#'   \item{coefN_readily}{Coefficient for readily available N per soil group.}
#'   \item{coefN_mineralised}{Mineralisation coefficient per soil group x C/N.}
#'   \item{coef_time}{`C_tempo` time adjustment factors by phase x cycle; in
#'         v0.2.0 also carries DPI 2026 percentages for N, P2O5 and K2O allowed
#'         per phase, plus `advance_allowed` and `husbandry` flags.}
#'   \item{s2.rast}{Example Sentinel-2 raster (5 bands) for vignettes, stored as
#'         a \code{terra} \code{PackedSpatRaster}. Unwrap with
#'         \code{terra::rast(s2.rast)} before use.}
#' }
#'
#' @section DPI 2026 additional lookup tables (v0.2.0):
#' \describe{
#'   \item{mas.table}{Maximum allowed doses (MAS) per crop (DPI 2026, RR 2/2024);
#'         includes standard N dose, MAS_N, max_increment, max_N_dose.}
#'   \item{crops.table}{Crop master list with genus/species, N fixation % and
#'         `no_till_reduction` flag (from foglio `Coltura`).}
#'   \item{crop_groups.table}{6 crop macro-groups: arboree, erbacee, foraggere,
#'         orticole, da_seme, baby_life.}
#'   \item{texture_groups.table}{Texture grouping with `specific_weight`, P
#'         immobilisation factor and soil weight at 20/30/40/50 cm.}
#'   \item{so.table, so_max_input}{SOM class (12) and maximum annual SO input
#'         (t ss/ha) per class.}
#'   \item{ph.table}{Soil pH classes (7).}
#'   \item{total_carbonate.table, active_carbonate.table}{Total and active carbonate
#'         classes for soil reactivity.}
#'   \item{p_availability.table, p_availability_meta}{Olsen-P availability classes and
#'         P <-> P2O5 conversion + P immobilisation factor.}
#'   \item{k_availability.table}{Exchangeable-K availability classes per texture grouping.}
#'   \item{fertilizer_types.table}{Fertiliser type classification (11 classes).}
#'   \item{organic_fertilizers.table}{21 organic matrices with ss, N, P2O5, K2O (min/avg/max),
#'         zootec flag, SO increment.}
#'   \item{efficiency.table}{DPI 2026 organic N efficiency: ID_Rag x level x
#'         sector x dose (220 rows).}
#'   \item{distribution_modalities.table}{22 distribution modalities (epoch + technique).}
#'   \item{cycle_modality.table}{Compatibility matrix crop-cycle x distribution
#'         modality x efficiency level.}
#'   \item{cycles.table, cycle_phases.table}{Crop cycles (6) and phase-duration (17).}
#'   \item{c_d.table}{Combined C (leaching) and fc_D (immobilisation) lookup
#'         (foglio C&D of Fert_Office v1.26).}
#' }
#'
#' @section DPI 2026 Scheda-standard datasets (v0.3.0):
#' \describe{
#'   \item{standard_pk_doses.table}{Base N, P2O5 and K2O standard doses
#'         per crop, with 4 dotation classes (Molto_Bassa, Bassa, Normale,
#'         Elevata) for P and K (239 rows, 14 cols).}
#'   \item{standard_decrements.table}{Crop-level catalogue of reduction
#'         factors (Rid_N_Resa, Ammendante precedente, SO elevato,
#'         Dopo medica/leguminosa, ecc.) for the scheda method.}
#'   \item{standard_increments.table}{Crop-level catalogue of increment
#'         factors (Resa alta, SO basso, Ristoppio paglie, Surplus pluvio,
#'         Terreno compattato, ecc.) for the scheda method; includes
#'         inc_N_max, Inc_P2O5_Max, Inc_K2O_Max DPI 2026 caps.}
#'   \item{standard_multicycle.table}{Pluriennali and multi-cut specific
#'         data (I/II anno husbandry, inizio produzione, incremento per
#'         taglio by K dotation class).}
#'   \item{mineral_fertilizers.table}{146 mineral / organo-mineral fertilisers from
#'         Fert_Office v1.26 foglio Concimi with N, P2O5, K2O titres (kg/q).}
#' }
#'
#' @examples
#' library(agrinutri)
#' head(uptake_table)
#' head(mas.table)
#' head(p_availability.table)
#' head(k_availability.table)
#' head(organic_fertilizers.table)
#'
#' @keywords datasets internal
NULL
