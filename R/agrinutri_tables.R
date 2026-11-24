#' Replace the coefficient tables of the balance
#'
#' Every coefficient of the nitrogen, phosphorus and potassium balances is read
#' from a bundled table (for example [uptake_table], [mas.table], [cb.table],
#' [e.table]). `agrinutri_tables()` makes the balance use other tables for the
#' rest of the session (or until it is called again), without editing the package:
#' start from the bundled table, change its values, and pass it by name. The
#' replacement must keep the columns of the bundled table.
#'
#' @param ... Named data frames, each replacing the bundled table of the same
#'   name, e.g. `uptake_table = my_uptake`. Call with no arguments to go back to
#'   the bundled tables.
#' @return The previous replacement list, invisibly (pass it to
#'   `options(agrinutri.tables = ...)` to restore it).
#' @export
#' @examples
#' my_uptake <- uptake_table
#' i <- my_uptake$crop == "Grain maize 500-700 (grain)"
#' my_uptake$N[i] <- my_uptake$N[i] * 1.1            # 10 percent higher unit uptake
#' old <- agrinutri_tables(uptake_table = my_uptake)
#' calc_crop_N_demand(10, "Grain maize 500-700 (grain)")$N_requirement   # 10 percent higher
#' agrinutri_tables()                                  # bundled tables again
agrinutri_tables <- function(...) {
  new <- list(...)
  if (length(new) && (is.null(names(new)) || any(!nzchar(names(new)))))
    stop("Pass the tables by name, e.g. agrinutri_tables(uptake_table = my_uptake).", call. = FALSE)
  for (n in names(new)) {
    ref <- agrinutri_data_get(n)
    if (!is.data.frame(new[[n]]) || !all(names(ref) %in% names(new[[n]])))
      stop(sprintf("`%s` must be a data frame with the columns of the bundled table.", n), call. = FALSE)
  }
  old <- getOption("agrinutri.tables")
  options(agrinutri.tables = if (length(new)) new else NULL)
  invisible(old)
}
