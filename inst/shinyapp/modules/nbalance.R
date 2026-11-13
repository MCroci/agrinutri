# modules/nbalance.R
# Field-scale crop N balance: form on the left, outputs on the right.

nBalanceUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(4,
      .agrinutri_card(
        h3("Crop and field inputs"),
        selectInput(ns("crop"), "Crop",
                    choices = .agrinutri_crop_choices(),
                    selected = .agrinutri_default_crop()),
        fluidRow(
          column(6, numericInput(ns("yield"), "Expected yield (t ha\u207B\u00B9)",
                                  value = 60, min = 0.1, step = 1)),
          column(6, selectInput(ns("ccp"),
                                "Climate period",
                                choices = .CCP_CHOICES,
                                selected = "Spring-summer crop 100-130 days"))
        ),
        h4("Soil analysis"),
        fluidRow(
          column(4, numericInput(ns("sand"), "Sand (%)", 50,  min = 0, max = 100)),
          column(4, numericInput(ns("clay"), "Clay (%)", 35,  min = 0, max = 100)),
          column(4, numericInput(ns("ntot"), "N tot (%)", 1.2, step = 0.1, min = 0))
        ),
        fluidRow(
          column(4, numericInput(ns("som"),  "SOM (%)",  1.2, step = 0.1)),
          column(4, numericInput(ns("cn"),   "C:N",      9.5, step = 0.1)),
          column(4, selectInput(ns("o2"),
                                "O2 availability",
                                choices = .O2_CHOICES,
                                selected = "Normal"))
        ),
        h4("Weather and history"),
        fluidRow(
          column(4, numericInput(ns("winter_rain"),
                                  "Winter rain (mm)", 160, step = 5)),
          column(4, numericInput(ns("spring_rain"),
                                  "Early-spring rain (mm)", 40, step = 5)),
          column(4, selectInput(ns("prev"),
                                  "Previous crop",
                                  choices = .PREV_CROP_CHOICES,
                                  selected = "Maize stalks removed"))
        ),
        fluidRow(
          column(4, selectInput(ns("source"),
                                  "Current-yr organic",
                                  choices = .SOURCE_CHOICES,
                                  selected = "Cattle slurry")),
          column(4, selectInput(ns("fertorg"),
                                  "Organic history",
                                  choices = .FERTORG_CHOICES,
                                  selected = "every year")),
          column(4, selectInput(ns("location"),
                                  "Location",
                                  choices = .LOCATION_CHOICES,
                                  selected = "Plain adjacent to urbanized areas"))
        ),
        numericInput(ns("forg_q"),
                     "Current-yr organic -- N delivered (kg N ha\u207B\u00B9)",
                     value = 100, min = 0, step = 5),
        conditionalPanel(
          condition = "output.research",
          ns = ns,
          .agrinutri_research_box(
            h4("Research overrides"),
            p(class = "agrinutri-muted",
              "Override the DPI 2026 default coefficients. Leave blank to use",
              "the bundled tables."),
            fluidRow(
              column(4, numericInput(ns("a_override"),
                                      "A -- crop demand (kg N/ha)", NA, step = 5)),
              column(4, numericInput(ns("b1_override"),
                                      "B1 -- mineralisation", NA, step = 5)),
              column(4, numericInput(ns("b2_override"),
                                      "B2 -- ready-N", NA, step = 5))
            )
          )
        ),
        tags$hr(),
        actionButton(ns("run"),
          tagList(icon("play"), " Compute balance"),
          class = "btn btn-lg btn-primary", width = "100%")
      )
    ),
    column(8,
      .agrinutri_card(
        tags$ul(class = "agrinutri-stepbar",
          tags$li(class = "active", "1. Balance"),
          tags$li("2. Distribution plan"),
          tags$li("3. Precision / VRT")),
        h3("Balance result"),
        uiOutput(ns("summary_box")),
        tags$hr(),
        h4("Waterfall from crop demand (A) to net mineral N to apply"),
        p(class = "agrinutri-muted",
          "Each red segment adds to the N requirement; each green segment",
          "reduces it; the running total lands on the blue bar (Net N*).",
          "The dashed line is the MAS cap for the selected crop."),
        plotOutput(ns("waterfall_plot"), height = "380px"),
        tags$hr(),
        h4("Compliance"),
        plotOutput(ns("gauge_plot"), height = "190px"),
        tags$hr(),
        h4("Breakdown of every balance term"),
        DT::DTOutput(ns("terms_dt")),
        tags$hr(),
        downloadButton(ns("dl_csv"), "Download CSV",
                       class = "btn btn-default"),
        span(" "),
        downloadButton(ns("dl_report"), "Download HTML report",
                       class = "btn btn-default"),
        span(" "),
        actionButton(ns("push_to_plan"),
          tagList(icon("arrow-right"), " Send N* to Distribution plan"),
          class = "btn btn-success")
      ),
      conditionalPanel(
        condition = "output.research",
        ns = ns,
        .agrinutri_research_box(
          h4("Raw N_balance() object"),
          verbatimTextOutput(ns("raw_print"))
        )
      )
    )
  )
}

nBalanceServer <- function(id, research_mode, app_state) {
  moduleServer(id, function(input, output, session) {
    output$research <- reactive(research_mode())
    outputOptions(output, "research", suspendWhenHidden = FALSE)

    bal <- eventReactive(input$run, {
      withProgress(message = "Computing N balance...", value = 0.3, {
        # All dropdowns return English canonical keys (agrinutri >= 0.12.0
        # reference tables are English-primary).
        args <- list(
          crop                 = input$crop,
          expected_yield_tons_ha = input$yield,
          ccp                  = input$ccp,
          sand                 = input$sand,
          clay                 = input$clay,
          Ntot                 = input$ntot,
          SOM                  = input$som,
          CN                   = input$cn,
          oxygen_availability  = input$o2,
          winter_rain          = input$winter_rain,
          start_spring_rain    = input$spring_rain,
          prev_crop            = input$prev,
          source               = if (identical(input$source, "None")) NA
                                  else input$source,
          fertorg_frequency    = input$fertorg,
          location             = input$location,
          forg_quantity        = input$forg_q
        )
        tryCatch(do.call(agrinutri::N_balance, args),
                 error = function(e) {
                   showNotification(conditionMessage(e), type = "error",
                                    duration = 10); NULL
                 })
      })
    })

    output$summary_box <- renderUI({
      b <- bal(); req(b)
      net <- net_value()
      mas <- mas_value()
      # Safe scalar comparison without length-0 pitfalls
      check <- if (is.finite(net) && is.finite(mas)) {
                  if (net > mas) "!" else "ok"
                } else "--"
      tagList(
        div(class = "agrinutri-kpi-row",
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value",
                   .agrinutri_fmt(net, 0)),
              span(class = "agrinutri-kpi-label",
                   "Net N* (kg N ha\u207B\u00B9)")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(mas, 0)),
              span(class = "agrinutri-kpi-label", "MAS cap")),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", check),
              span(class = "agrinutri-kpi-label", "MAS check"))
        )
      )
    })

    terms_df <- reactive({
      b <- bal(); req(b)
      nms <- c("A","B1","B2","C1","C2","D","E","F","Forg","G")
      vals <- vapply(nms, function(nm) {
        v <- tryCatch(b[[nm]], error = function(e) NA_real_)
        # Accept numeric scalar, numeric vector, or nested list entries;
        # fall back to 0 if the term is missing/not a number (so the
        # waterfall / table still render without propagating NAs).
        if (is.null(v) || length(v) == 0) return(0)
        v <- suppressWarnings(as.numeric(v)[1])
        if (!is.finite(v)) 0 else v
      }, numeric(1))
      data.frame(
        term  = nms,
        sign  = c("+","-","-","+","+","+","-","-","-","-"),
        value = round(vals, 1),
        stringsAsFactors = FALSE
      )
    })

    # Coerce any input to a finite numeric scalar; NA_real_ on failure.
    .as_scalar <- function(x) {
      if (is.null(x) || length(x) == 0) return(NA_real_)
      v <- suppressWarnings(as.numeric(x)[1])
      if (!is.finite(v)) NA_real_ else v
    }
    net_value <- reactive({
      b <- bal(); req(b)
      .as_scalar(tryCatch(agrinutri::calculate_N_fertilization(b),
                          error = function(e) NA_real_))
    })
    mas_value <- reactive({
      v <- tryCatch(
        suppressWarnings(agrinutri::get_MAS(crop = input$crop)),
        error = function(e) NULL)
      if (is.null(v)) return(NA_real_)
      .as_scalar(v$mas_N)
    })

    output$waterfall_plot <- renderPlot({
      df <- terms_df(); req(df, nrow(df) > 0)
      # use absolute values for the helper (it re-applies sign)
      df$value <- abs(df$value)
      df$term  <- factor(df$term, levels = df$term)
      .agrinutri_waterfall(df, net_value = net_value(), mas_cap = mas_value())
    })

    output$gauge_plot <- renderPlot({
      nv <- net_value(); mv <- mas_value()
      # Do NOT req(is.finite(nv)) - we still want to render the "no
      # data" gauge when net is NA (e.g. balance had partial NAs).
      f_contrib <- tryCatch({
        b <- bal()
        v <- suppressWarnings(sum(c(
          if (!is.null(b$Forg)) as.numeric(b$Forg)[1] else 0,
          if (!is.null(b$F))    as.numeric(b$F)[1]    else 0),
          na.rm = TRUE))
        if (!is.finite(v)) 0 else v
      }, error = function(e) 0)
      .agrinutri_compliance_pair(net = nv, mas = mv,
                              zvn_applied = f_contrib,
                              zvn_limit = 170)
    })

    output$terms_dt <- DT::renderDT({
      df <- terms_df(); req(df)
      DT::datatable(df, rownames = FALSE,
                    options = list(dom = "t", paging = FALSE,
                                   ordering = FALSE))
    })

    output$raw_print <- renderPrint({
      b <- bal(); req(b); print(b)
    })

    output$dl_csv <- .agrinutri_download_csv(NULL, terms_df, "Nbalance_terms")

    output$dl_report <- downloadHandler(
      filename = function()
        sprintf("agrinutri_report_%s.html",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content = function(file) {
        if (!requireNamespace("rmarkdown", quietly = TRUE)) {
          # Minimal fallback: static HTML snapshot
          df <- terms_df()
          writeLines(c(
            "<!doctype html><html><head><meta charset='utf-8'>",
            "<title>agrinutri balance report</title>",
            "<style>body{font-family:sans-serif;margin:40px}",
            "table{border-collapse:collapse}td,th{padding:4px 10px;",
            "border-bottom:1px solid #ddd}</style></head><body>",
            sprintf("<h1>agrinutri balance report - %s</h1>",
                    format(Sys.time(), "%Y-%m-%d %H:%M")),
            sprintf("<p><b>Crop:</b> %s &middot; <b>Yield:</b> %.1f t/ha</p>",
                    input$crop, input$yield),
            sprintf("<h2>Net mineral N to apply: %.0f kg N/ha</h2>",
                    net_value()),
            "<table><thead><tr><th>Term</th><th>Sign</th>",
            "<th>Value (kg N/ha)</th></tr></thead><tbody>",
            paste(sprintf(
              "<tr><td>%s</td><td>%s</td><td>%.1f</td></tr>",
              df$term, df$sign, df$value), collapse = ""),
            "</tbody></table></body></html>"
          ), file)
          return()
        }
        # Build a dedicated render environment populated with the
        # helpers and the data the Rmd will reference.
        render_env <- new.env(parent = globalenv())
        render_env$report_terms <- terms_df()
        render_env$report_net   <- net_value()
        render_env$report_mas   <- mas_value()
        render_env$report_crop  <- input$crop
        render_env$report_yield <- input$yield
        render_env$.agrinutri_waterfall <- .agrinutri_waterfall

        tpl <- tempfile(fileext = ".Rmd")
        writeLines(c(
          "---",
          "title: \"agrinutri balance report\"",
          sprintf("date: \"%s\"", format(Sys.time(), "%Y-%m-%d %H:%M")),
          "output:",
          "  html_document:",
          "    self_contained: true",
          "    theme: flatly",
          "---",
          "",
          "```{r setup, include=FALSE}",
          "knitr::opts_chunk$set(echo = FALSE, warning = FALSE,",
          "                      message = FALSE, fig.width = 9,",
          "                      fig.height = 4.2)",
          "```",
          "",
          "## Crop: `r report_crop`",
          "Expected yield: **`r sprintf('%.1f t/ha', report_yield)`**  ",
          "Source: DPI 2026 (Emilia-Romagna Integrated Production).",
          "",
          "### Net mineral N to apply: **`r sprintf('%.0f kg N/ha', report_net)`**",
          "",
          "### Waterfall",
          "```{r}",
          "df <- report_terms",
          "df$value <- abs(df$value)",
          "df$term  <- factor(df$term, levels = df$term)",
          ".agrinutri_waterfall(df, net_value = report_net, mas_cap = report_mas)",
          "```",
          "",
          "### Breakdown",
          "```{r results='asis'}",
          "knitr::kable(report_terms,",
          "             col.names = c('Term','Sign','kg N/ha'))",
          "```"
        ), tpl)

        rmarkdown::render(
          tpl,
          output_file = file,
          envir       = render_env,
          quiet       = TRUE,
          intermediates_dir = tempdir(),
          clean       = TRUE
        )
      }
    )

    observeEvent(input$push_to_plan, {
      b <- bal(); req(b)
      app_state$n_bal_obj <- b
      app_state$n_target  <- tryCatch(agrinutri::calculate_N_fertilization(b),
                                      error = function(e) NA)
      app_state$crop      <- input$crop
      app_state$mas_cap   <- tryCatch(
        agrinutri::get_MAS(crop = input$crop)$mas_N,
        error = function(e) NA)
      showNotification("N target sent to Distribution plan tab.",
                       type = "message", duration = 3)
    })
  })
}
