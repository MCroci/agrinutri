#' Launch the agrinutri Shiny web interface
#'
#' Opens the bundled Shiny application in the user's default browser,
#' exposing the core of the agrinutri package (N, P, K balance, distribution
#' plan, variable-rate prescription, Sentinel-2 NNI pipeline and spatial
#' balance) through interactive forms and maps. Two working modes are
#' available: \emph{agronomist view} (default, focused on the outputs
#' actually needed for on-farm recommendations) and \emph{research view}
#' (toggle at the top-right of the navigation bar, exposes intermediate
#' balance terms and coefficient overrides).
#'
#' @param launch.browser Logical. Whether to open the default browser.
#'   Default \code{TRUE}.
#' @param port Integer. TCP port to listen on. Default \code{NULL} lets
#'   Shiny pick a free port.
#' @param host Character. Interface to bind. Default \code{"127.0.0.1"}
#'   for local use. Set to \code{"0.0.0.0"} to expose the app on the LAN.
#' @param ... Further arguments passed to \code{\link[shiny]{runApp}}.
#'
#' @return Invisibly, the value returned by \code{\link[shiny]{runApp}}.
#'
#' @examples
#' \dontrun{
#' agrinutri::run_app()                              # local, open in browser
#' agrinutri::run_app(host = "0.0.0.0", port = 3838) # serve on the LAN
#' }
#' @export
run_app <- function(launch.browser = TRUE, port = NULL,
                    host = "127.0.0.1", ...) {
  app_dir <- system.file("shinyapp", package = "agrinutri")
  if (!nzchar(app_dir) || !dir.exists(app_dir))
    stop("agrinutri web interface not found. ",
         "Was the package installed with its inst/shinyapp directory?")

  required <- c("shiny", "shinyjs", "DT", "ggplot2", "patchwork")
  missing  <- required[!vapply(required,
    function(p) requireNamespace(p, quietly = TRUE), logical(1))]
  if (length(missing) > 0)
    stop("Missing dependencies for the web interface: ",
         paste(missing, collapse = ", "),
         ". Install with: install.packages(c('",
         paste(missing, collapse = "', '"), "'))")

  invisible(shiny::runApp(app_dir,
                          launch.browser = launch.browser,
                          port = port, host = host, ...))
}
