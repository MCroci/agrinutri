#' agrinutri Package Data
#'
#' Internal datasets used by the agrinutri package for nitrogen (and, from v0.2.0,
#' phosphorus and potassium) balance calculations following the Emilia-Romagna
#' Integrated Production Guidelines (DPI) (Annex 2 - balance method,
#' Annexes 3, 4, 6, 7, 9) and the FertDPI / Fert_Office reference tool
#' (v1.26, February 2026).
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
#' (1) sandy textures (S, SF, FS), (2) loamy textures
#' (L, F, FL, FSA, FA), (3) clay textures (FLA, AS, AL, A).
#' Most tables with character keys use English names, with the Fert_Office
#' labels in `*_it` columns; `standard_pk_doses.table$crop` keeps the
#' Fert_Office labels (English names in `crop_en`) and
#' `mineral_fertilizers.table` lists commercial product names.
#'
#' @section Core N datasets:
#' \describe{
#'   \item{uptake_table}{Crop unit absorption/asportation coefficients for
#'         N, P2O5 and K2O (from Fert_Office sheet A). 247 crops in v0.2.0.}
#'   \item{e.table}{Previous crop: N kg/ha from previous crop residues, with
#'         legume flag and Fert_Office label.}
#'   \item{f.table}{Coefficients of recovery for organic fertilisation applied
#'         in previous years (4 sources x 4 frequencies = 16 rows).}
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
#'   \item{mas.table}{Maximum allowed doses (MAS) per crop (DPI 2026, Regional Regulation 2/2024);
#'         includes standard N dose, MAS_N, max_increment, max_N_dose.}
#'   \item{crops.table}{Crop master list with genus/species, N fixation % and
#'         `no_till_reduction` flag (from the Fert_Office crop sheet).}
#'   \item{crop_groups.table}{6 crop macro-groups: tree crops and small fruits,
#'         field crops, forage crops, vegetables, seed crops, baby leaf.}
#'   \item{texture_groups.table}{Texture grouping with `specific_weight`, P
#'         immobilisation factor and soil weight at 20/30/40/50 cm.}
#'   \item{so.table, so_max_input}{SOM class (12) and maximum annual SOM input
#'         (t dry matter/ha) per class.}
#'   \item{ph.table}{Soil pH classes (7).}
#'   \item{total_carbonate.table, active_carbonate.table}{Total and active carbonate
#'         classes for soil reactivity.}
#'   \item{p_availability.table, p_availability_meta}{Olsen-P availability classes and
#'         P <-> P2O5 conversion + P immobilisation factor.}
#'   \item{k_availability.table}{Exchangeable-K availability classes per texture grouping.}
#'   \item{fertilizer_types.table}{Fertiliser type classification (11 classes).}
#'   \item{organic_fertilizers.table}{21 organic matrices with dry matter, N, P2O5, K2O (min/avg/max),
#'         livestock flag, SOM increment.}
#'   \item{efficiency.table}{DPI 2026 organic N efficiency: ID_Rag x level x
#'         sector x dose (220 rows).}
#'   \item{distribution_modalities.table}{22 distribution modalities (epoch + technique).}
#'   \item{cycle_modality.table}{Compatibility matrix crop-cycle x distribution
#'         modality x efficiency level.}
#'   \item{cycles.table, cycle_phases.table}{Crop cycles (6) and phase-duration (17).}
#'   \item{c_d.table}{Combined C (leaching) and fc_D (immobilisation) lookup
#'         (sheet C&D of Fert_Office v1.26).}
#' }
#'
#' @section DPI 2026 standard-dose datasets (v0.3.0):
#' \describe{
#'   \item{standard_pk_doses.table}{Base N, P2O5 and K2O standard doses
#'         per crop, with 4 soil availability classes (very low, low, normal,
#'         high) for P and K (239 rows, 14 cols).}
#'   \item{standard_decrements.table}{Crop-level catalogue of reduction
#'         factors (yield, previous soil amendment, high SOM,
#'         after alfalfa or legume, etc.) for the standard-dose method.}
#'   \item{standard_increments.table}{Crop-level catalogue of increment
#'         factors (high yield, low SOM, straw burial, rainfall surplus,
#'         compacted soil, etc.) for the standard-dose method; includes
#'         inc_N_max, Inc_P2O5_Max, Inc_K2O_Max DPI 2026 caps.}
#'   \item{standard_multicycle.table}{Perennial and multi-cut specific
#'         data (1st/2nd husbandry year, start of production, increment per
#'         cut by soil K class).}
#'   \item{mineral_fertilizers.table}{146 mineral / organo-mineral fertilisers from
#'         the Fert_Office v1.26 fertiliser sheet with N, P2O5, K2O titres (kg/q).}
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
