# Launch the agrinutri Shiny web interface

Opens the bundled Shiny application in the user's default browser,
exposing the core of the agrinutri package (N, P, K balance,
distribution plan, variable-rate prescription, Sentinel-2 NNI pipeline
and spatial balance) through interactive forms and maps. Two working
modes are available: *agronomist view* (default, focused on the outputs
actually needed for on-farm recommendations) and *research view* (toggle
at the top-right of the navigation bar, exposes intermediate balance
terms and coefficient overrides).

## Usage

``` r
run_app(launch.browser = TRUE, port = NULL, host = "127.0.0.1", ...)
```

## Arguments

- launch.browser:

  Logical. Whether to open the default browser. Default `TRUE`.

- port:

  Integer. TCP port to listen on. Default `NULL` lets Shiny pick a free
  port.

- host:

  Character. Interface to bind. Default `"127.0.0.1"` for local use. Set
  to `"0.0.0.0"` to expose the app on the LAN.

- ...:

  Further arguments passed to
  [`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Invisibly, the value returned by
[`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Examples

``` r
if (FALSE) { # \dontrun{
agrinutri::run_app()                              # local, open in browser
agrinutri::run_app(host = "0.0.0.0", port = 3838) # serve on the LAN
} # }
```
