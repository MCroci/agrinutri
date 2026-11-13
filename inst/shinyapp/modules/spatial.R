# modules/spatial.R
# Pixel-by-pixel N balance over a stack of soil rasters.

spatialUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(4,
      .agrinutri_card(
        h3(icon("map"), " Spatial N balance"),
        p(class = "agrinutri-muted",
          "Apply N_balance() pixel-by-pixel to a stack of soil rasters",
          "(Ntot, SOM, Clay, Sand, CN). The Cremonesi field ships with",
          "the package as a 12-ha demo."),
        radioButtons(ns("source_sel"),
          "Soil stack source",
          choices = c("Bundled Cremonesi demo" = "cremonesi",
                      "Upload GeoTIFFs"        = "custom"),
          selected = "cremonesi"),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'custom'", ns("source_sel")),
          fileInput(ns("tn_tif"),   "TN (%) GeoTIFF",
                    accept = c(".tif", ".tiff")),
          fileInput(ns("som_tif"),  "SOM (%) GeoTIFF",
                    accept = c(".tif", ".tiff")),
          fileInput(ns("clay_tif"), "Clay (%) GeoTIFF",
                    accept = c(".tif", ".tiff")),
          fileInput(ns("sand_tif"), "Sand (%) GeoTIFF",
                    accept = c(".tif", ".tiff")),
          fileInput(ns("cn_tif"),   "CN ratio GeoTIFF",
                    accept = c(".tif", ".tiff"))
        ),
        selectInput(ns("crop"), "Crop",
                    choices = .agrinutri_crop_choices(),
                    selected = .agrinutri_default_crop()),
        numericInput(ns("yield"), "Expected yield (t ha\u207B\u00B9)",
                      value = 60, min = 0.1, step = 1),
        selectInput(ns("source"),
                    "Current-yr organic",
                    choices = .SOURCE_CHOICES,
                    selected = "Cattle slurry"),
        fluidRow(
          column(6, numericInput(ns("winter_rain"),
                                  "Winter rain (mm)", 160, step = 5)),
          column(6, numericInput(ns("spring_rain"),
                                  "Early-spring rain (mm)", 40, step = 5))
        ),
        actionButton(ns("run"),
          tagList(icon("play"), " Compute spatial balance"),
          class = "btn btn-primary btn-lg", width = "100%")
      )
    ),
    column(8,
      .agrinutri_card(
        h3("Field-level N to apply"),
        plotOutput(ns("nmap_plot"), height = "360px"),
        h4("Within-field distribution"),
        plotOutput(ns("nmap_hist"), height = "180px"),
        tags$hr(),
        uiOutput(ns("spat_summary")),
        downloadButton(ns("dl_tif"),
                        "Download N map (GeoTIFF)",
                        class = "btn btn-default")
      )
    )
  )
}

spatialServer <- function(id, research_mode, app_state) {
  moduleServer(id, function(input, output, session) {

    soil_stack <- reactive({
      if (!requireNamespace("terra", quietly = TRUE)) return(NULL)
      if (identical(input$source_sel, "cremonesi")) {
        dir <- system.file("extdata", package = "agrinutri")
        paths <- file.path(dir, c("Cremonesi_TN.tif",
                                  "Cremonesi_SOM.tif",
                                  "Cremonesi_Clay.tif",
                                  "Cremonesi_Sand.tif",
                                  "Cremonesi_CNratio.tif"))
        if (!all(file.exists(paths))) return(NULL)
        s <- terra::rast(paths)
        names(s) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
        s
      } else {
        req(input$tn_tif, input$som_tif, input$clay_tif,
            input$sand_tif, input$cn_tif)
        s <- terra::rast(c(input$tn_tif$datapath,
                           input$som_tif$datapath,
                           input$clay_tif$datapath,
                           input$sand_tif$datapath,
                           input$cn_tif$datapath))
        names(s) <- c("TN", "SOM", "Clay", "Sand", "CNratio")
        s
      }
    })

    result <- eventReactive(input$run, {
      st <- soil_stack()
      if (is.null(st)) {
        showNotification("No soil stack available.", type = "error"); return(NULL)
      }
      withProgress(message = "Running spatial balance...", value = 0.3, {
        tryCatch(agrinutri::spatial_N_balance(
          soil_stack = st,
          expected_yield_tons_ha = input$yield,
          crop   = input$crop,
          ccp    = "Spring-summer crop 100-130 days",
          winter_rain = input$winter_rain,
          start_spring_rain = input$spring_rain,
          prev_crop = "Maize stalks removed",
          source = if (identical(input$source, "None")) NA else input$source,
          fertorg_frequency = "every year",
          location = "Plain adjacent to urbanized areas",
          forg_quantity = 100
        ), error = function(e) {
          showNotification(conditionMessage(e), type = "error",
                           duration = 10); NULL
        })
      })
    })

    output$nmap_plot <- renderPlot({
      r <- result(); req(r)
      lyr <- tryCatch(r[["N_to_apply"]], error = function(e) r)
      terra::plot(lyr,
        main = "Mineral N to apply (kg N/ha)",
        col = hcl.colors(100, "RdYlGn"))
    })
    output$nmap_hist <- renderPlot({
      r <- result(); req(r)
      lyr <- tryCatch(r[["N_to_apply"]], error = function(e) r)
      mean_val <- tryCatch(terra::global(lyr, "mean", na.rm = TRUE)[1,1],
                            error = function(e) NA)
      .agrinutri_raster_hist(lyr, breaks = mean_val,
                          xlab = "N rate (kg N/ha)")
    })
    output$spat_summary <- renderUI({
      r <- result(); req(r)
      lyr <- tryCatch(r[["N_to_apply"]], error = function(e) r)
      mn <- terra::global(lyr, "mean", na.rm = TRUE)[1,1]
      mi <- terra::global(lyr, "min",  na.rm = TRUE)[1,1]
      ma <- terra::global(lyr, "max",  na.rm = TRUE)[1,1]
      div(class = "agrinutri-kpi-row",
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mn, 1)),
              span(class = "agrinutri-kpi-label", "mean")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mi, 1)),
              span(class = "agrinutri-kpi-label", "min")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(ma, 1)),
              span(class = "agrinutri-kpi-label", "max")))
    })
    output$dl_tif <- downloadHandler(
      filename = function()
        sprintf("Spatial_Nbalance_%s.tif",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content  = function(file) {
        r <- result(); req(r)
        lyr <- tryCatch(r[["N_to_apply"]], error = function(e) r)
        terra::writeRaster(lyr, file, overwrite = TRUE)
      })
  })
}
