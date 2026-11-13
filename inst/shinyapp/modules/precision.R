# modules/precision.R
# NDVI / NDRE-based variable-rate N and the S2 -> NNI pipeline.

precisionUI <- function(id) {
  ns <- NS(id)
  tabsetPanel(
    id = ns("prec_tabs"),
    # -- Strip prescription sub-tab --------------------------------
    tabPanel("Strip prescription (machine width)",
      fluidRow(
        column(4,
          .agrinutri_card(
            h3(icon("truck"), " Strip builder inputs"),
            p(class = "agrinutri-muted",
              "Generate machine-width strips along an A-B line inside a",
              "farm plot and assign a dose per strip. Output is ready to",
              "be exported in any tractor-monitor format."),
            selectInput(ns("strip_plot"),
              "Plot (from demo farm)",
              choices = c("P01 Campo Grande"   = 1,
                          "P03 Lower Ditch"    = 3,
                          "P06 Riverbank"      = 6),
              selected = 1),
            fluidRow(
              column(4, numericInput(ns("machine_w"),
                                      "Machine width (m)",
                                      24, min = 6, max = 48, step = 1)),
              column(4, numericInput(ns("cell_len"),
                                      "Cell length (m, 0 = continuous)",
                                      0, min = 0, max = 500, step = 5)),
              column(4, numericInput(ns("angle_deg"),
                                      "A-B angle (deg, NA = auto)",
                                      NA, min = 0, max = 360, step = 5))
            ),
            selectInput(ns("ab_source"),
              "A-B line source",
              choices = c("Longest side (auto)"           = "long",
                          "Click twice on map to draw"    = "click",
                          "Upload LINESTRING"             = "upload"),
              selected = "long"),
            conditionalPanel(
              condition = sprintf("input['%s'] == 'upload'", ns("ab_source")),
              fileInput(ns("ab_file"),
                         "A-B LINESTRING (GeoJSON)",
                         accept = c(".geojson", ".json"))
            ),
            conditionalPanel(
              condition = sprintf("input['%s'] == 'click'", ns("ab_source")),
              leaflet::leafletOutput(ns("ab_map"), height = "240px"),
              div(class = "agrinutri-muted",
                "Click once for A, again for B. Click a third time to reset."),
              actionButton(ns("ab_reset"), "Reset A-B points",
                            class = "btn btn-default btn-sm")
            ),
            selectInput(ns("strip_var"),
              "Variability method",
              choices = c("Uniform (baseline)"        = "uniform",
                          "VI calibration curve"      = "calibration",
                          "NNI zones"                 = "nni",
                          "VI quantile classes"       = "classes"),
              selected = "uniform"),
            fluidRow(
              column(4, numericInput(ns("strip_n_target"),
                                      "N target (kg/ha)", 160, step = 5)),
              column(4, numericInput(ns("strip_min"),
                                      "min dose", 40, step = 5)),
              column(4, numericInput(ns("strip_max"),
                                      "max dose", 220, step = 5))
            ),
            conditionalPanel(
              condition = sprintf("input['%s'] == 'calibration' || input['%s'] == 'classes'",
                                  ns("strip_var"), ns("strip_var")),
              fluidRow(
                column(6, numericInput(ns("strip_vi_low"),
                                        "VI low anchor", 0.35, step = 0.01)),
                column(6, numericInput(ns("strip_vi_high"),
                                        "VI high anchor", 0.80, step = 0.01))
              ),
              actionButton(ns("strip_load_ndvi"),
                "Load demo NDVI raster",
                class = "btn btn-default", icon = icon("download"))
            ),
            conditionalPanel(
              condition = sprintf("input['%s'] == 'nni'", ns("strip_var")),
              fluidRow(
                column(6, numericInput(ns("strip_thr_lo"),
                                        "deficient threshold", 0.90, step = 0.05)),
                column(6, numericInput(ns("strip_thr_hi"),
                                        "excessive threshold", 1.10, step = 0.05))
              ),
              actionButton(ns("strip_load_nni"),
                "Load demo NNI raster",
                class = "btn btn-default", icon = icon("download"))
            ),
            checkboxInput(ns("strip_preserve_mean"),
              "Rescale to preserve field-mean dose", TRUE),
            tags$hr(),
            actionButton(ns("run_strip"),
              tagList(icon("play"), " Build strips"),
              class = "btn btn-primary btn-lg", width = "100%")
          )
        ),
        column(8,
          .agrinutri_card(
            h3("Prescription strips"),
            plotOutput(ns("strip_plot_out"), height = "380px"),
            h4("Dose summary"),
            plotOutput(ns("strip_hist"), height = "160px"),
            uiOutput(ns("strip_kpi")),
            tags$hr(),
            h4("Download prescription"),
            checkboxGroupInput(ns("strip_formats"),
              label = NULL,
              choices = c("Shapefile"                  = "shp",
                          "GeoJSON"                    = "geojson",
                          "KML"                        = "kml",
                          "GeoPackage"                 = "gpkg",
                          "John Deere-ready Shapefile" = "johndeere",
                          "Trimble-ready Shapefile"    = "trimble",
                          "ISOXML (TASKDATA.XML)"      = "isoxml"),
              selected = c("shp", "isoxml"),
              inline = TRUE),
            downloadButton(ns("dl_strip_zip"),
              "Download bundle (.zip)",
              class = "btn btn-primary")
          )
        )
      )
    ),
    # -- VRT tab ----
    tabPanel("Variable-rate N (NDVI / NDRE)",
      fluidRow(
        column(4,
          .agrinutri_card(
            h3(icon("satellite"), " VRT inputs"),
            fileInput(ns("vi_file"),
                      "Normalised 0-1 VI raster (GeoTIFF)",
                      accept = c(".tif", ".tiff")),
            actionButton(ns("vi_demo"),
              "Load synthetic demo NDVI",
              class = "btn btn-default", icon = icon("download")),
            selectInput(ns("method"), "Redistribution method",
                        choices = c("Holland & Schepers" = "holland",
                                    "Calibration curve (linear)"  = "linear",
                                    "Calibration curve (quadratic)" = "quadratic"),
                        selected = "holland"),
            fluidRow(
              column(4, numericInput(ns("n_dose"),
                                      "N target (kg N/ha)",
                                      value = 160, min = 0, step = 5)),
              column(4, numericInput(ns("minN"),
                                      "min N", 20, min = 0, step = 5)),
              column(4, numericInput(ns("maxN"),
                                      "max N", 160, min = 0, step = 5))
            ),
            checkboxInput(ns("use_ntarget"),
              "Use N* from N balance tab", value = TRUE),
            conditionalPanel(
              condition = "output.research",
              ns = ns,
              .agrinutri_research_box(
                h4("Research overrides"),
                fluidRow(
                  column(6, numericInput(ns("ndvi_ref"),
                                          "NDVI_ref (SI = 1)",
                                          NA, step = 0.01)),
                  column(6, numericInput(ns("mas_cap"),
                                          "MAS cap override (kg N/ha)",
                                          NA, step = 5))
                )
              )
            ),
            actionButton(ns("run_vrt"),
              tagList(icon("play"), " Compute VRT prescription"),
              class = "btn btn-primary btn-lg", width = "100%")
          )
        ),
        column(8,
          .agrinutri_card(
            h3("VRT prescription map"),
            plotOutput(ns("vi_plot"),  height = "220px"),
            plotOutput(ns("vrt_plot"), height = "260px"),
            tags$hr(),
            h4("Rate distribution"),
            plotOutput(ns("vrt_hist"), height = "180px"),
            uiOutput(ns("vrt_summary")),
            downloadButton(ns("dl_tif"),
                           "Download prescription (GeoTIFF)",
                           class = "btn btn-default")
          )
        )
      )
    ),
    # -- NNI empirical tab (no GPR models) ---------------------------
    tabPanel("NNI (empirical, VI-based)",
      fluidRow(
        column(4,
          .agrinutri_card(
            h3(icon("seedling"), " VI -> NNI (no GPR)"),
            p(class = "agrinutri-muted",
              "Derive an NNI map directly from one vegetation index",
              "using a published linear regression. No GPR models",
              "or model-directory path required. Suggested when you",
              "only have a single-index raster (NDRE / NDVI /",
              "CIred-edge)."),
            fileInput(ns("emp_vi_file"),
                       "VI raster (GeoTIFF)",
                       accept = c(".tif", ".tiff")),
            actionButton(ns("emp_vi_demo"),
              "Load synthetic demo (NDRE)",
              class = "btn btn-default", icon = icon("download")),
            fluidRow(
              column(6, selectInput(ns("emp_index"),
                                     "Vegetation index",
                                     choices = c("NDRE", "NDVI", "CIred_edge"),
                                     selected = "NDRE")),
              column(6, selectInput(ns("emp_crop"),
                                     "Crop",
                                     choices = c("wheat", "maize",
                                                 "rice", "barley"),
                                     selected = "wheat"))
            ),
            conditionalPanel(
              condition = "output.research",
              ns = ns,
              .agrinutri_research_box(
                h4("Override regression coefficients"),
                p(class = "agrinutri-muted",
                  "If you have locally calibrated slope / intercept",
                  "values, override the defaults here."),
                fluidRow(
                  column(6, numericInput(ns("emp_slope"),
                                          "slope", NA, step = 0.1)),
                  column(6, numericInput(ns("emp_intercept"),
                                          "intercept", NA, step = 0.01))
                )
              )
            ),
            actionButton(ns("run_emp_nni"),
              tagList(icon("play"), " Compute NNI (empirical)"),
              class = "btn btn-primary btn-lg", width = "100%")
          )
        ),
        column(8,
          .agrinutri_card(
            h3("NNI map and zones"),
            plotOutput(ns("emp_nni_plot"),   height = "300px"),
            plotOutput(ns("emp_zones_plot"), height = "240px"),
            uiOutput(ns("emp_summary"))
          )
        )
      )
    ),
    # -- NNI tab (GPR) -----------------------------------------------
    tabPanel("NNI (S2 L2A, GPR)",
      fluidRow(
        column(4,
          .agrinutri_card(
            h3(icon("seedling"), " Sentinel-2 -> NNI"),
            selectInput(ns("nni_crop"), "Crop",
                        choices = .NNI_CROP_CHOICES,
                        selected = "wheat"),
            fileInput(ns("s2_file"),
                      "S2 L2A 10-band GeoTIFF",
                      accept = c(".tif", ".tiff")),
            textInput(ns("model_dir"),
                      "Path to GPR models directory (leave empty to use bundled models)",
                      value = ""),
            uiOutput(ns("model_dir_status")),
            selectInput(ns("nni_path"), "Canopy-N path",
                        choices = c("CNC_Cprot (protein, direct)" = "CNC_Cprot",
                                    "CNC_Cab (chlorophyll * k)"   = "CNC_Cab"),
                        selected = "CNC_Cprot"),
            conditionalPanel(
              condition = "output.research",
              ns = ns,
              .agrinutri_research_box(
                h4("Parameter overrides"),
                p(class = "agrinutri-muted",
                  "Leave blank to use the crop defaults from",
                  "crop_params_NNI()."),
                fluidRow(
                  column(6, numericInput(ns("alpha_leaf"),
                                          "alpha_leaf", NA, step = 0.01)),
                  column(6, numericInput(ns("k_nchl"),
                                          "k (N:Chl)", NA, step = 1))
                ),
                fluidRow(
                  column(6, numericInput(ns("thr_lo"),
                                          "NNI deficient threshold",
                                          0.90, step = 0.05)),
                  column(6, numericInput(ns("thr_hi"),
                                          "NNI excessive threshold",
                                          1.10, step = 0.05))
                )
              )
            ),
            actionButton(ns("run_nni"),
              tagList(icon("play"), " Run NNI pipeline"),
              class = "btn btn-primary btn-lg", width = "100%"),
            tags$br(), tags$br(),
            uiOutput(ns("nni_caveats"))
          )
        ),
        column(8,
          .agrinutri_card(
            h3("NNI map and zones"),
            plotOutput(ns("nni_plot"),   height = "300px"),
            h4("Distribution of NNI values"),
            plotOutput(ns("nni_hist"),   height = "200px"),
            h4("Area fraction per agronomic zone"),
            plotOutput(ns("zones_bar"),  height = "220px"),
            plotOutput(ns("zones_plot"), height = "260px"),
            uiOutput(ns("nni_summary"))
          )
        )
      )
    )
  )
}

precisionServer <- function(id, research_mode, app_state) {
  moduleServer(id, function(input, output, session) {
    output$research <- reactive(research_mode())
    outputOptions(output, "research", suspendWhenHidden = FALSE)

    # ---- VRT --------------------------------------------------------
    vi_rast_val <- reactiveVal(NULL)
    observeEvent(input$vi_file, {
      if (!requireNamespace("terra", quietly = TRUE)) return()
      vi_rast_val(terra::rast(input$vi_file$datapath))
    })
    observeEvent(input$vi_demo, {
      if (!requireNamespace("sf", quietly = TRUE)) return()
      ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
      fd <- sf::st_read(ex, quiet = TRUE)[1, ]
      vi_rast_val(.agrinutri_demo_ndvi(fd))
      showNotification("Demo NDVI raster loaded.",
                       type = "message", duration = 3)
    })
    vi_rast <- reactive({ req(vi_rast_val()); vi_rast_val() })

    # Robust scalar-numeric reader: accepts NULL / zero-length / NA and
    # always returns a finite numeric scalar or NA_real_.
    .as_num <- function(x) {
      if (is.null(x) || length(x) == 0) return(NA_real_)
      v <- suppressWarnings(as.numeric(x)[1])
      if (!is.finite(v)) NA_real_ else v
    }
    .is_ok_num <- function(x) is.finite(.as_num(x))

    vrt_out <- eventReactive(input$run_vrt, {
      r <- vi_rast(); req(r)
      n_target <- if (isTRUE(input$use_ntarget) &&
                      .is_ok_num(app_state$n_target))
        .as_num(app_state$n_target) else .as_num(input$n_dose)
      method <- if (input$method == "holland") "holland" else "calibration"
      mas_over <- if (.is_ok_num(input$mas_cap)) .as_num(input$mas_cap)
                   else .as_num(app_state$mas_cap)

      withProgress(message = "Computing VRT...", value = 0.5, {
        tryCatch(agrinutri::variable_rate_N(
          ndvi_raster = r,
          n_dose      = n_target,
          method      = method,
          minN        = input$minN,
          maxN        = input$maxN,
          mas_cap     = mas_over
        ), error = function(e) {
          showNotification(conditionMessage(e), type = "error",
                           duration = 10); NULL
        })
      })
    })

    output$vi_plot <- renderPlot({
      r <- vi_rast(); req(r)
      terra::plot(r, main = "Input VI", col = hcl.colors(100, "YlGn"))
    })

    output$vrt_plot <- renderPlot({
      o <- vrt_out(); req(o)
      r <- o$rate_raster %||% o
      terra::plot(r,
        main = "VRT prescription (kg N/ha)",
        col = hcl.colors(100, "RdYlGn", rev = TRUE))
    })
    output$vrt_hist <- renderPlot({
      o <- vrt_out(); req(o)
      r <- o$rate_raster %||% o
      nt <- if (isTRUE(input$use_ntarget) &&
                .is_ok_num(app_state$n_target))
              .as_num(app_state$n_target)
            else .as_num(input$n_dose)
      .agrinutri_raster_hist(r, breaks = nt,
                         xlab = "N rate (kg N/ha)")
    })
    `%||%` <- function(a, b) if (is.null(a)) b else a

    output$vrt_summary <- renderUI({
      o <- vrt_out(); req(o)
      r  <- o$rate_raster %||% o
      mn <- terra::global(r, "mean", na.rm = TRUE)[1,1]
      mi <- terra::global(r, "min",  na.rm = TRUE)[1,1]
      ma <- terra::global(r, "max",  na.rm = TRUE)[1,1]
      div(class = "agrinutri-kpi-row",
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mn, 0)),
              span(class = "agrinutri-kpi-label", "mean")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mi, 0)),
              span(class = "agrinutri-kpi-label", "min")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(ma, 0)),
              span(class = "agrinutri-kpi-label", "max")))
    })

    output$dl_tif <- downloadHandler(
      filename = function()
        sprintf("VRT_%s.tif", format(Sys.time(), "%Y%m%d_%H%M")),
      content  = function(file) {
        o <- vrt_out(); req(o)
        terra::writeRaster(o$rate_raster %||% o, file,
                           overwrite = TRUE)
      })

    # ---- NNI (empirical VI-based) ----------------------------------
    emp_vi_val <- reactiveVal(NULL)
    observeEvent(input$emp_vi_file, {
      if (!requireNamespace("terra", quietly = TRUE)) return()
      emp_vi_val(terra::rast(input$emp_vi_file$datapath))
    })
    observeEvent(input$emp_vi_demo, {
      if (!requireNamespace("sf", quietly = TRUE)) return()
      ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
      fd <- sf::st_read(ex, quiet = TRUE)[1, ]
      # Re-range NDVI 0.3-0.9 -> NDRE 0.15-0.55
      r  <- .agrinutri_demo_ndvi(fd)
      v  <- terra::values(r, mat = FALSE)
      v  <- 0.15 + (v - 0.30) / (0.90 - 0.30) * (0.55 - 0.15)
      terra::values(r) <- v
      emp_vi_val(r)
      showNotification("Demo NDRE raster loaded.",
                       type = "message", duration = 3)
    })

    emp_nni_out <- eventReactive(input$run_emp_nni, {
      r <- emp_vi_val(); req(r)
      sl <- if (.is_ok_num(input$emp_slope)) .as_num(input$emp_slope) else NULL
      it <- if (.is_ok_num(input$emp_intercept)) .as_num(input$emp_intercept)
             else NULL
      tryCatch(agrinutri::nni_from_vi_empirical(
        vi_raster = r,
        index     = input$emp_index,
        crop      = input$emp_crop,
        slope     = sl, intercept = it),
        error = function(e) {
          showNotification(conditionMessage(e), type = "error",
                           duration = 10); NULL
        })
    })

    output$emp_nni_plot <- renderPlot({
      o <- emp_nni_out(); req(o)
      terra::plot(o$NNI, main = sprintf("NNI (%s -> %s regression)",
                                         o$index, o$crop),
                  col = hcl.colors(100, "RdYlGn"))
    })
    output$emp_zones_plot <- renderPlot({
      o <- emp_nni_out(); req(o)
      terra::plot(o$zones,
                  main = "Zones (1 deficient / 2 optimal / 3 excessive)",
                  col = c("#C0392B", "#2F7A44", "#1F4E79"))
    })
    output$emp_summary <- renderUI({
      o <- emp_nni_out(); req(o)
      mn <- terra::global(o$NNI, "mean", na.rm = TRUE)[1,1]
      div(class = "agrinutri-kpi-row",
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mn, 2)),
              span(class = "agrinutri-kpi-label", "mean NNI")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value",
                   sprintf("%.2f", o$slope)),
              span(class = "agrinutri-kpi-label",
                   sprintf("slope (%s)", o$index))),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value",
                   sprintf("%.2f", o$intercept)),
              span(class = "agrinutri-kpi-label", "intercept")))
    })

    # ---- NNI (GPR) --------------------------------------------------
    output$nni_caveats <- renderUI({
      div(class = "agrinutri-alert agrinutri-alert-info",
          tags$strong("Calibration caveat. "),
          "Defaults for alpha_leaf and k (N:Chl) usually introduce",
          tags$b("15-30 % bias"), " in operational NNI. A minimal local",
          "recalibration dataset is 30-50 plot-level samples of biomass",
          "and total N across the target growing season.")
    })

    # Detect bundled GPR models (inst/extdata/SENTINEL2_L2A_*.json)
    .bundled_model_dir <- reactive({
      d <- system.file("extdata", package = "agrinutri")
      if (!nzchar(d)) return(NA_character_)
      needed <- paste0("SENTINEL2_L2A_",
                        c("LAI","Cm","Cw","FVC","Cab","laiCab",
                          "CNC_Cab","CNC_Cprot"), ".json")
      have <- file.exists(file.path(d, needed))
      if (all(have)) d else NA_character_
    })
    # Resolve the actual directory to pass to estimate_biophysical()
    .nni_model_dir <- reactive({
      user_path <- trimws(input$model_dir %||% "")
      if (nzchar(user_path)) return(user_path)
      .bundled_model_dir()
    })

    output$model_dir_status <- renderUI({
      user_path <- trimws(input$model_dir %||% "")
      bundled   <- .bundled_model_dir()
      if (nzchar(user_path)) {
        div(class = "agrinutri-alert agrinutri-alert-info",
            tags$strong("Using user path: "), user_path)
      } else if (!is.na(bundled)) {
        div(class = "agrinutri-alert agrinutri-alert-ok",
            tags$strong("Bundled GPR models detected. "),
            tags$br(),
            "Found 8 PROSAIL-trained .json files in ",
            tags$code(bundled),
            ". The pipeline will use them automatically.")
      } else {
        div(class = "agrinutri-alert agrinutri-alert-warn",
            tags$strong("GPR models not found. "),
            tags$br(),
            "Either supply the path manually, copy the 8 .json files ",
            "from ",
            tags$a(href = "https://github.com/daviddkovacs/pyeogpr",
                   "pyeogpr"),
            " into ", tags$code("inst/extdata/"),
            " and reinstall, or switch to the ",
            tags$strong("NNI (empirical, VI-based)"), " tab.")
      }
    })

    nni_out <- eventReactive(input$run_nni, {
      req(input$s2_file)
      model_path <- .nni_model_dir()
      if (is.null(model_path) || is.na(model_path) ||
          !nzchar(model_path) || !dir.exists(model_path)) {
        showNotification(
          "No valid GPR model directory. Paste a path or use the empirical tab.",
          type = "error", duration = 10); return(NULL)
      }
      if (!requireNamespace("terra", quietly = TRUE)) {
        showNotification("Install 'terra' to run the NNI pipeline.",
                         type = "error"); return(NULL)
      }
      params <- tryCatch(agrinutri::crop_params_NNI(input$nni_crop),
                         error = function(e) list())
      if (.is_ok_num(input$alpha_leaf))
        params$alpha_leaf <- .as_num(input$alpha_leaf)
      if (.is_ok_num(input$k_nchl))
        params$k_NChl     <- .as_num(input$k_nchl)

      vars <- c("LAI", "Cm",
                switch(input$nni_path, CNC_Cprot = "CNC_Cprot",
                                       CNC_Cab   = "CNC_Cab"),
                "FVC")
      withProgress(message = "Running S2 -> NNI pipeline...", value = 0.3, {
        maps <- tryCatch(agrinutri::estimate_biophysical(
          raster_path = input$s2_file$datapath,
          output_dir  = tempfile("nni_", fileext = ""),
          variables   = vars,
          model_dir   = model_path
        ), error = function(e) {
          showNotification(conditionMessage(e), type = "error",
                           duration = 10); NULL
        })
        if (is.null(maps)) return(NULL)
        tryCatch(agrinutri::compute_NNI_from_S2(
          lai_rast  = maps$LAI,
          cm_rast   = maps$Cm,
          cnc_rast  = maps[[input$nni_path]],
          cnc_layer = input$nni_path,
          crop      = input$nni_crop,
          params    = params,
          fvc       = maps$FVC,
          nni_thresholds = c(input$thr_lo, input$thr_hi)
        ), error = function(e) {
          showNotification(conditionMessage(e), type = "error",
                           duration = 10); NULL
        })
      })
    })

    output$nni_plot <- renderPlot({
      o <- nni_out(); req(o)
      terra::plot(o$NNI, main = "NNI",
                  col = hcl.colors(100, "RdYlGn"))
    })
    output$zones_plot <- renderPlot({
      o <- nni_out(); req(o)
      terra::plot(o$zones, main = "Zones (1 deficient / 2 optimal / 3 excessive)",
                  col = c("#C0392B", "#2F7A44", "#1F4E79"))
    })

    # ---- Strip prescription builder ---------------------------------
    demo_field <- reactive({
      if (!requireNamespace("sf", quietly = TRUE)) return(NULL)
      ex <- system.file("extdata/example_farm.geojson", package = "agrinutri")
      farm <- sf::st_read(ex, quiet = TRUE)
      idx <- as.integer(input$strip_plot %||% 1)
      farm[idx, , drop = FALSE]
    })
    demo_ndvi <- reactiveVal(NULL)
    demo_nni  <- reactiveVal(NULL)

    observeEvent(input$strip_load_ndvi, {
      fd <- demo_field(); req(fd)
      demo_ndvi(.agrinutri_demo_ndvi(fd))
      showNotification("Demo NDVI raster loaded.",
                       type = "message", duration = 3)
    })
    observeEvent(input$strip_load_nni, {
      fd <- demo_field(); req(fd)
      demo_nni(.agrinutri_demo_nni(fd))
      showNotification("Demo NNI raster loaded.",
                       type = "message", duration = 3)
    })

    # --- Interactive A-B drawing (leaflet) ----------------------------
    ab_clicks <- reactiveValues(a = NULL, b = NULL)
    observeEvent(input$ab_reset, {
      ab_clicks$a <- NULL; ab_clicks$b <- NULL
    })
    observeEvent(input$ab_map_click, {
      pt <- input$ab_map_click
      if (is.null(ab_clicks$a)) {
        ab_clicks$a <- c(pt$lng, pt$lat)
      } else if (is.null(ab_clicks$b)) {
        ab_clicks$b <- c(pt$lng, pt$lat)
      } else {
        # third click -> reset
        ab_clicks$a <- c(pt$lng, pt$lat); ab_clicks$b <- NULL
      }
    })

    output$ab_map <- leaflet::renderLeaflet({
      fd <- demo_field(); req(fd)
      if (!requireNamespace("leaflet", quietly = TRUE)) return(NULL)
      fw <- sf::st_transform(fd, 4326)
      bb <- sf::st_bbox(fw)
      leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery) |>
        leaflet::addPolygons(data = fw, fillColor = "#1F4E79",
                             color = "#fff", weight = 2,
                             fillOpacity = 0.25) |>
        leaflet::fitBounds(bb[[1]], bb[[2]], bb[[3]], bb[[4]])
    })

    observe({
      proxy <- leaflet::leafletProxy(session$ns("ab_map"))
      leaflet::clearGroup(proxy, "ab")
      if (!is.null(ab_clicks$a)) {
        leaflet::addCircleMarkers(proxy,
          lng = ab_clicks$a[1], lat = ab_clicks$a[2],
          color = "#2F7A44", radius = 7, label = "A",
          group = "ab")
      }
      if (!is.null(ab_clicks$b)) {
        leaflet::addCircleMarkers(proxy,
          lng = ab_clicks$b[1], lat = ab_clicks$b[2],
          color = "#C0392B", radius = 7, label = "B",
          group = "ab")
        leaflet::addPolylines(proxy,
          lng = c(ab_clicks$a[1], ab_clicks$b[1]),
          lat = c(ab_clicks$a[2], ab_clicks$b[2]),
          color = "#C0392B", weight = 3,
          group = "ab")
      }
    })

    # A-B resolver -----------------------------------------------------
    ab_line_val <- reactive({
      src <- input$ab_source
      if (identical(src, "upload") && !is.null(input$ab_file))
        return(tryCatch(sf::st_read(input$ab_file$datapath, quiet = TRUE),
                        error = function(e) NULL))
      if (identical(src, "click") &&
          !is.null(ab_clicks$a) && !is.null(ab_clicks$b)) {
        m <- rbind(ab_clicks$a, ab_clicks$b)
        ls <- sf::st_linestring(m)
        return(sf::st_sfc(ls, crs = 4326) |>
                 sf::st_sf(geometry = _))
      }
      NULL
    })

    strip_out <- eventReactive(input$run_strip, {
      fd <- demo_field(); req(fd)
      if (!requireNamespace("sf", quietly = TRUE)) {
        showNotification("'sf' required.", type = "error"); return(NULL)
      }
      angle_d <- if (.is_ok_num(input$angle_deg)) .as_num(input$angle_deg)
                  else NULL
      cell_l  <- if (.is_ok_num(input$cell_len) &&
                     .as_num(input$cell_len) > 0)
                    .as_num(input$cell_len) else NULL
      tryCatch(agrinutri::build_strip_prescription(
        field         = fd,
        machine_width = .as_num(input$machine_w),
        cell_length   = cell_l,
        angle_deg     = angle_d,
        ab_line       = ab_line_val(),
        variability   = input$strip_var,
        vi_raster     = demo_ndvi(),
        nni_raster    = demo_nni(),
        n_target      = .as_num(input$strip_n_target),
        min_dose      = .as_num(input$strip_min),
        max_dose      = .as_num(input$strip_max),
        vi_low        = .as_num(input$strip_vi_low),
        vi_high       = .as_num(input$strip_vi_high),
        thr_lo        = .as_num(input$strip_thr_lo),
        thr_hi        = .as_num(input$strip_thr_hi),
        preserve_mean = isTRUE(input$strip_preserve_mean)
      ), error = function(e) {
        showNotification(conditionMessage(e), type = "error",
                         duration = 10); NULL
      })
    })

    output$strip_plot_out <- renderPlot({
      s <- strip_out(); req(s)
      doses <- s$dose
      pal <- colorRampPalette(c("#2F7A44", "#F6E7C7", "#C0392B"))(100)
      if (diff(range(doses, na.rm = TRUE)) == 0) {
        col_idx <- rep(50L, length(doses))
      } else {
        col_idx <- as.integer(round(
          (doses - min(doses, na.rm = TRUE)) /
            diff(range(doses, na.rm = TRUE)) * 99)) + 1
      }
      # Project to a metric CRS with equal x/y for true shape
      sm <- sf::st_transform(s, 3857)
      op <- par(mar = c(1, 1, 2, 1), xaxt = "n", yaxt = "n",
                 bty = "n")
      plot(sf::st_geometry(sm), col = pal[col_idx],
           border = "#333", lwd = 0.7, asp = 1,
           main = sprintf(
             "Prescription %s - %d cells - mean %.0f kg N/ha",
             if (any(duplicated(round(sm$area_ha, 3))) &&
                 nrow(sm) > 10)
               "grid" else "strips",
             nrow(sm),
             weighted.mean(doses, s$area_ha, na.rm = TRUE)))
      par(op)
    })

    output$strip_hist <- renderPlot({
      s <- strip_out(); req(s)
      df <- data.frame(dose = s$dose, area_ha = s$area_ha)
      ggplot2::ggplot(df, ggplot2::aes(x = dose, weight = area_ha)) +
        ggplot2::geom_histogram(bins = 20, fill = "#D5E4F0",
                                colour = "#1F4E79", linewidth = 0.4) +
        ggplot2::labs(x = "dose (kg N/ha)", y = "area (ha)") +
        ggplot2::theme_minimal(base_size = 11)
    })

    output$strip_kpi <- renderUI({
      s <- strip_out(); req(s)
      mean_d <- weighted.mean(s$dose, s$area_ha)
      total_kg <- sum(s$dose * s$area_ha)
      div(class = "agrinutri-kpi-row",
        div(class = "agrinutri-kpi",
            span(class = "agrinutri-kpi-value", nrow(s)),
            span(class = "agrinutri-kpi-label", "strips")),
        div(class = "agrinutri-kpi",
            span(class = "agrinutri-kpi-value",
                 .agrinutri_fmt(sum(s$area_ha), 2)),
            span(class = "agrinutri-kpi-label", "total ha")),
        div(class = "agrinutri-kpi",
            span(class = "agrinutri-kpi-value",
                 .agrinutri_fmt(mean_d, 0)),
            span(class = "agrinutri-kpi-label", "mean dose (kg/ha)")),
        div(class = "agrinutri-kpi",
            span(class = "agrinutri-kpi-value",
                 .agrinutri_fmt(total_kg, 0)),
            span(class = "agrinutri-kpi-label", "total kg N")))
    })

    output$dl_strip_zip <- downloadHandler(
      filename = function()
        sprintf("strips_%s.zip",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content = function(file) {
        s <- strip_out(); req(s, nrow(s) > 0)
        fmts <- input$strip_formats
        if (length(fmts) == 0) {
          showNotification("Select at least one format.",
                           type = "warning"); return()
        }
        tmpdir <- tempfile("strips_"); dir.create(tmpdir)
        tryCatch(
          agrinutri::export_prescription_all(
            s, output_dir = tmpdir, basename = "strip_prescription",
            formats = fmts, dose_field = "dose",
            isoxml_opts = list(task_name = "Strip prescription",
                               product   = "N fertiliser",
                               unit      = "kg/ha")),
          error = function(e) {
            showNotification(conditionMessage(e), type = "error",
                             duration = 10); return()
          })
        old <- getwd(); on.exit(setwd(old), add = TRUE)
        setwd(tmpdir)
        utils::zip(file, files = list.files(".", recursive = TRUE),
                   flags = "-r9X")
      }
    )
    output$nni_hist <- renderPlot({
      o <- nni_out(); req(o)
      .agrinutri_raster_hist(o$NNI,
                         breaks = c(input$thr_lo, input$thr_hi),
                         xlab = "NNI")
    })
    output$zones_bar <- renderPlot({
      o <- nni_out(); req(o)
      z <- .agrinutri_zone_area(o$zones)
      .agrinutri_zone_bar(z)
    })
    output$nni_summary <- renderUI({
      o <- nni_out(); req(o)
      mn <- terra::global(o$NNI, "mean", na.rm = TRUE)[1,1]
      z  <- .agrinutri_zone_area(o$zones)
      div(class = "agrinutri-kpi-row",
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mn, 2)),
              span(class = "agrinutri-kpi-label", "mean NNI")),
          div(class = "agrinutri-kpi kpi-deficient",
              span(class = "agrinutri-kpi-value",
                   sprintf("%.1f%%", z$percent[z$zone == "Deficient"])),
              span(class = "agrinutri-kpi-label",
                   sprintf("deficient (%.1f ha)",
                           z$ha[z$zone == "Deficient"]))),
          div(class = "agrinutri-kpi kpi-optimal",
              span(class = "agrinutri-kpi-value",
                   sprintf("%.1f%%", z$percent[z$zone == "Optimal"])),
              span(class = "agrinutri-kpi-label",
                   sprintf("optimal (%.1f ha)",
                           z$ha[z$zone == "Optimal"]))),
          div(class = "agrinutri-kpi kpi-excessive",
              span(class = "agrinutri-kpi-value",
                   sprintf("%.1f%%", z$percent[z$zone == "Excessive"])),
              span(class = "agrinutri-kpi-label",
                   sprintf("excessive (%.1f ha)",
                           z$ha[z$zone == "Excessive"]))))
    })
  })
}
