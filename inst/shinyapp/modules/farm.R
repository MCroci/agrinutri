# modules/farm.R
# Farm-level workflow: upload a GeoJSON of plots, run farm_balance() on
# every feature, visualise the result on a leaflet map and offer the
# enriched layer for download.

farmUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(4,
      .agrinutri_card(
        h3(icon("tractor"), " Farm / Azienda"),
        p(class = "agrinutri-lead",
          "Carica un GeoJSON dove ogni feature \u00E8 un appezzamento. ",
          tags$br(),
          "Ogni feature deve avere le colonne richieste da ", tags$code("N_balance()"),
          " (colture DPI 2026, analisi del suolo, storico organico)."),
        radioButtons(ns("source_sel"),
          "Origine dati",
          choices = c("Demo inclusa (35.5 ha, 8 appezzamenti)" = "demo",
                      "Carica un tuo GeoJSON / Shapefile"      = "upload"),
          selected = "demo"),
        conditionalPanel(
          condition = sprintf("input['%s'] == 'upload'", ns("source_sel")),
          fileInput(ns("farm_file"),
                    "GeoJSON file",
                    accept = c(".geojson", ".json"))
        ),
        checkboxInput(ns("run_p"),
          "Compute also P2O5 balance (needs olsen_value column)",
          FALSE),
        checkboxInput(ns("run_k"),
          "Compute also K2O balance (needs k_value column)",
          FALSE),
        actionButton(ns("run"),
          tagList(icon("play"), " Compute farm balance"),
          class = "btn btn-primary btn-lg", width = "100%"),
        tags$hr(),
        uiOutput(ns("kpi_farm")),
        tags$hr(),
        downloadButton(ns("dl_geojson"),
          "Download enriched GeoJSON",
          class = "btn btn-default"),
        span("  "),
        downloadButton(ns("dl_csv"),
          "Download summary CSV",
          class = "btn btn-default"),
        tags$hr(),
        h4("Prescription map export for on-board monitors"),
        p(class = "agrinutri-muted",
          "Write the N_target layer in the format accepted by the",
          "target tractor monitor. Select one or more and click",
          "Download: the result is a zip of the chosen formats."),
        checkboxGroupInput(ns("rx_formats"),
          label = NULL,
          choices = c("Shapefile (universal)"        = "shp",
                      "GeoJSON"                      = "geojson",
                      "KML (Google Earth)"           = "kml",
                      "GeoPackage"                   = "gpkg",
                      "John Deere-ready Shapefile"   = "johndeere",
                      "Trimble-ready Shapefile"      = "trimble",
                      "ISOXML (TASKDATA.XML)"        = "isoxml"),
          selected = c("shp", "isoxml"),
          inline = TRUE),
        fluidRow(
          column(6, textInput(ns("rx_product"),
                               "ISOXML product",   "Urea 46 pct")),
          column(3, textInput(ns("rx_unit"),
                               "ISOXML unit",      "kg/ha")),
          column(3, textInput(ns("rx_task"),
                               "ISOXML task name", "N top-dress"))
        ),
        downloadButton(ns("dl_rx"),
          "Download prescription bundle (.zip)",
          class = "btn btn-primary")
      )
    ),
    column(8,
      .agrinutri_card(
        h3("Plot map"),
        conditionalPanel(
          condition = sprintf("typeof output['%s'] !== 'undefined'",
                              ns("has_leaflet")),
          leaflet::leafletOutput(ns("leaf_map"), height = "440px")
        ),
        # Fallback plot if leaflet is missing
        plotOutput(ns("fallback_map"), height = "440px"),
        tags$hr(),
        h4("N* distribution across plots"),
        plotOutput(ns("nt_hist"), height = "200px"),
        h4("Summary table"),
        DT::DTOutput(ns("summary_dt"))
      )
    )
  )
}

farmServer <- function(id, research_mode, app_state) {
  moduleServer(id, function(input, output, session) {

    output$has_leaflet <- reactive(
      requireNamespace("leaflet", quietly = TRUE) &&
      requireNamespace("sf", quietly = TRUE))
    outputOptions(output, "has_leaflet", suspendWhenHidden = FALSE)

    input_path <- reactive({
      if (identical(input$source_sel, "demo")) {
        p <- system.file("extdata/example_farm.geojson", package = "agrinutri")
        if (!nzchar(p)) NULL else p
      } else {
        req(input$farm_file)
        input$farm_file$datapath
      }
    })

    farm_obj <- eventReactive(input$run, {
      p <- input_path()
      if (is.null(p) || !file.exists(p)) {
        showNotification("No input layer available.", type = "error")
        return(NULL)
      }
      if (!requireNamespace("sf", quietly = TRUE)) {
        showNotification(
          "Install 'sf' to use the farm-level workflow.",
          type = "error", duration = 10)
        return(NULL)
      }
      withProgress(message = "Running per-plot balance...", value = 0.3, {
        tryCatch(agrinutri::farm_balance(
          p, p_balance = isTRUE(input$run_p),
             k_balance = isTRUE(input$run_k)),
          error = function(e) {
            showNotification(conditionMessage(e),
                             type = "error", duration = 10)
            NULL
          })
      })
    })

    output$kpi_farm <- renderUI({
      f <- farm_obj(); req(f)
      n_plots <- nrow(f)
      total_ha <- sum(as.numeric(f$area_ha), na.rm = TRUE)
      total_N  <- sum(as.numeric(f$N_total_kg), na.rm = TRUE)
      n_mas_ko <- sum(!isTRUE(all(f$MAS_ok)) & !f$MAS_ok, na.rm = TRUE)
      div(class = "agrinutri-kpi-row",
        div(class = "agrinutri-kpi",
          span(class = "agrinutri-kpi-value", n_plots),
          span(class = "agrinutri-kpi-label", "plots")),
        div(class = "agrinutri-kpi",
          span(class = "agrinutri-kpi-value",
               .agrinutri_fmt(total_ha, 1)),
          span(class = "agrinutri-kpi-label", "total ha")),
        div(class = "agrinutri-kpi",
          span(class = "agrinutri-kpi-value",
               .agrinutri_fmt(total_N, 0)),
          span(class = "agrinutri-kpi-label", "total kg N")),
        div(class = "agrinutri-kpi",
          span(class = "agrinutri-kpi-value", n_mas_ko),
          span(class = "agrinutri-kpi-label", "MAS breaches")))
    })

    # ---- Leaflet map --------------------------------------------------
    output$leaf_map <- leaflet::renderLeaflet({
      f <- farm_obj(); req(f)
      if (!requireNamespace("leaflet", quietly = TRUE) ||
          !requireNamespace("sf", quietly = TRUE))
        return(NULL)
      f_wgs <- sf::st_transform(f, 4326)
      rng <- range(f_wgs$N_target, na.rm = TRUE)
      if (!all(is.finite(rng)) || diff(rng) == 0) rng <- c(0, 200)
      pal <- leaflet::colorNumeric(
        palette = c("#D5ECDB", "#F6E7C7", "#F2D7D5", "#C0392B"),
        domain  = rng, na.color = "#CCCCCC")
      pop <- sprintf(paste0(
        "<b>%s</b> (%s)<br>",
        "<b>Coltura:</b> %s<br>",
        "<b>Area:</b> %.2f ha<br>",
        "<b>N target:</b> %.0f kg N/ha<br>",
        "<b>MAS:</b> %.0f kg N/ha %s<br>",
        "<b>N totale:</b> %.0f kg"),
        f_wgs$plot_id, f_wgs$plot_name, f_wgs$crop,
        f_wgs$area_ha, f_wgs$N_target,
        f_wgs$MAS_cap,
        ifelse(f_wgs$MAS_ok, "<span style='color:#2F7A44'>&#10003;</span>",
               "<span style='color:#C0392B'>&#10007;</span>"),
        f_wgs$N_total_kg)
      leaflet::leaflet(f_wgs) |>
        leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery,
                                  group = "Aerial") |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap,
                                  group = "OSM") |>
        leaflet::addLayersControl(
          baseGroups = c("Aerial", "OSM"),
          options = leaflet::layersControlOptions(collapsed = FALSE)) |>
        leaflet::addPolygons(
          fillColor = ~pal(N_target),
          color = "#333333", weight = 1.3, fillOpacity = 0.75,
          label  = ~plot_id,
          labelOptions = leaflet::labelOptions(noHide = TRUE, textsize = "12px",
                                               direction = "center",
                                               style = list("font-weight"="bold")),
          popup  = pop,
          highlightOptions = leaflet::highlightOptions(
            weight = 2.5, color = "#000", bringToFront = TRUE)) |>
        leaflet::addLegend("bottomright", pal = pal, values = ~N_target,
                           title = "N target<br>(kg N/ha)",
                           opacity = 0.9)
    })

    # Fallback static map when leaflet/sf are missing
    output$fallback_map <- renderPlot({
      if (requireNamespace("leaflet", quietly = TRUE) &&
          requireNamespace("sf", quietly = TRUE)) {
        plot.new(); return(invisible())
      }
      f <- farm_obj(); req(f)
      plot(sf::st_geometry(f), col = "#D5E4F0", border = "#333",
           main = "Farm plots (install 'leaflet' for interactive map)")
    })

    # ---- Summary table ------------------------------------------------
    summary_df <- reactive({
      f <- farm_obj(); req(f)
      df <- as.data.frame(f)
      df$geometry <- NULL
      keep <- intersect(
        c("plot_id","plot_name","crop","area_ha","expected_yield_tons_ha",
          "source","forg_quantity","N_target","MAS_cap","MAS_ok",
          "N_total_kg","P2O5_target","K2O_target","balance_error"),
        names(df))
      df[, keep, drop = FALSE]
    })

    output$summary_dt <- DT::renderDT({
      df <- summary_df(); req(df)
      DT::datatable(df, rownames = FALSE,
                    options = list(pageLength = 10,
                                   scrollX = TRUE)) |>
        DT::formatStyle("MAS_ok",
          backgroundColor = DT::styleEqual(
            c(TRUE, FALSE),
            c("#D5ECDB", "#F2D7D5")))
    })

    # ---- N target histogram -------------------------------------------
    output$nt_hist <- renderPlot({
      df <- summary_df(); req(df)
      ggplot2::ggplot(df,
        ggplot2::aes(x = reorder(plot_id, -N_target), y = N_target,
                     fill = ifelse(MAS_ok, "ok", "breach"))) +
        ggplot2::geom_col(colour = "grey30", width = 0.7) +
        ggplot2::geom_text(ggplot2::aes(label = sprintf("%.0f", N_target)),
                            vjust = -0.4, size = 3.5) +
        ggplot2::geom_hline(yintercept = 170, linetype = "dotted",
                            colour = "grey40") +
        ggplot2::annotate("text", x = 1, y = 172,
                          label = "ZVN 170 kg/ha",
                          hjust = 0, size = 3.2, colour = "grey40") +
        ggplot2::scale_fill_manual(values = c(
          ok = "#D5E4F0", breach = "#F2D7D5"),
          guide = "none") +
        ggplot2::labs(x = NULL, y = "N* (kg N/ha)") +
        ggplot2::theme_minimal(base_size = 12) +
        ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
    })

    # ---- Downloads ----------------------------------------------------
    output$dl_geojson <- downloadHandler(
      filename = function()
        sprintf("agrinutri_farm_%s.geojson",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content = function(file) {
        f <- farm_obj(); req(f)
        sf::st_write(f, file, driver = "GeoJSON",
                     delete_dsn = TRUE, quiet = TRUE)
      }
    )
    output$dl_csv <- downloadHandler(
      filename = function()
        sprintf("agrinutri_farm_summary_%s.csv",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content = function(file) {
        df <- summary_df(); req(df)
        utils::write.csv(df, file, row.names = FALSE)
      }
    )

    # Prescription-map bundle (multi-format zip)
    output$dl_rx <- downloadHandler(
      filename = function()
        sprintf("agrinutri_prescription_%s.zip",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content = function(file) {
        f <- farm_obj(); req(f, nrow(f) > 0)
        formats <- input$rx_formats
        if (length(formats) == 0) {
          showNotification("Select at least one output format.",
                           type = "warning"); return()
        }
        tmpdir <- tempfile("rx_"); dir.create(tmpdir)
        iso <- list(task_name = input$rx_task,
                    product   = input$rx_product,
                    unit      = input$rx_unit)
        tryCatch(
          agrinutri::export_prescription_all(
            f, output_dir = tmpdir, basename = "prescription",
            formats = formats,
            dose_field = "N_target",
            isoxml_opts = iso),
          error = function(e) {
            showNotification(conditionMessage(e), type = "error",
                             duration = 10); return()
          })
        # Zip everything in the tmpdir
        old <- getwd(); on.exit(setwd(old), add = TRUE)
        setwd(tmpdir)
        utils::zip(file, files = list.files(".", recursive = TRUE),
                   flags = "-r9X")
      }
    )
  })
}
