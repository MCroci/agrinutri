# modules/plan.R
# Builds a fertilisation plan from the N, P, K targets stored in app_state.

planUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(4,
      .agrinutri_card(
        h3(icon("truck"), " Plan inputs"),
        uiOutput(ns("targets_box")),
        tags$hr(),
        h4("Organic application"),
        fluidRow(
          column(6, selectInput(ns("org_fert"),
                                  "Organic fertiliser",
                                  choices = c(
                                    "None"                           = "None",
                                    "Dairy cattle slurry"            = "Dairy cattle slurry",
                                    "Beef cattle slurry"             = "Beef cattle slurry",
                                    "Pig slurry"                     = "Pig slurry",
                                    "Cattle manure"                  = "Cattle manure",
                                    "Mixed composted amendment"      = "Mixed composted amendment",
                                    "Whole digestate (biomass / cattle effluent)" =
                                      "Whole digestate (biomass / cattle effluent)"),
                                  selected = "Dairy cattle slurry")),
          column(6, numericInput(ns("org_q"),
                                  "Quantity (t/m\u00B3 ha\u207B\u00B9)",
                                  30, min = 0, step = 5))
        ),
        fluidRow(
          column(6, numericInput(ns("org_year"), "Application year",
                                  2026, min = 2000, step = 1)),
          column(6, selectInput(ns("org_modality"),
                                  "Application epoch",
                                  choices = c(
                                    "Pre-sowing"          = 1,
                                    "Pre-sowing + cover"  = 2,
                                    "Side-dress"          = 3),
                                  selected = 1))
        ),
        selectInput(ns("org_level"),
                    "Distribution technique",
                    choices = c("High efficiency"   = "alta",
                                "Medium efficiency" = "media",
                                "Low efficiency"    = "bassa"),
                    selected = "media"),

        tags$hr(),
        h4("Mineral application"),
        fluidRow(
          column(6, selectInput(ns("min_fert"),
                                  "Mineral fertiliser",
                                  choices = c(
                                    "None",
                                    "UREA AGRICOLA PRIL.46%",
                                    "NITRATO AMMONICO 26%",
                                    "NITRATO AMMONICO 34%",
                                    "SOLFATO AMMONICO 21%",
                                    "NPK 15-15-15"),
                                  selected = "UREA AGRICOLA PRIL.46%")),
          column(6, numericInput(ns("min_q"),
                                  "Quantity (q ha\u207B\u00B9)",
                                  3, min = 0, step = 0.5))
        ),
        selectInput(ns("min_epoch"),
                    "Application epoch",
                    choices = c(
                      "Pre-sowing"           = 1,
                      "Side-dress stage 1"   = 11,
                      "Side-dress stage 2"   = 12),
                    selected = 11),
        checkboxInput(ns("zvn"),
                      "Enforce 170 kg N ha\u207B\u00B9 ZVN limit",
                      value = TRUE),
        tags$hr(),
        actionButton(ns("run_plan"),
          tagList(icon("play"), " Build plan"),
          class = "btn btn-primary btn-lg", width = "100%")
      )
    ),
    column(8,
      .agrinutri_card(
        h3("Fertilisation plan"),
        uiOutput(ns("alerts_box")),
        h4("Split vs. target and regulatory limits"),
        plotOutput(ns("split_plot"), height = "170px"),
        tags$hr(),
        h4("Application rows"),
        DT::DTOutput(ns("plan_dt")),
        tags$hr(),
        downloadButton(ns("dl_csv"), "Download plan CSV",
                       class = "btn btn-default")
      )
    )
  )
}

planServer <- function(id, research_mode, app_state) {
  moduleServer(id, function(input, output, session) {

    output$targets_box <- renderUI({
      tags$div(class = "agrinutri-kpi-row",
        tags$div(class = "agrinutri-kpi",
          tags$span(class = "agrinutri-kpi-value",
                    .agrinutri_fmt(app_state$n_target, 0)),
          tags$span(class = "agrinutri-kpi-label",
                    "N* (kg N ha\u207B\u00B9)")),
        tags$div(class = "agrinutri-kpi",
          tags$span(class = "agrinutri-kpi-value",
                    .agrinutri_fmt(app_state$p_target, 0)),
          tags$span(class = "agrinutri-kpi-label",
                    "P2O5* (kg ha\u207B\u00B9)")),
        tags$div(class = "agrinutri-kpi",
          tags$span(class = "agrinutri-kpi-value",
                    .agrinutri_fmt(app_state$k_target, 0)),
          tags$span(class = "agrinutri-kpi-label",
                    "K2O* (kg ha\u207B\u00B9)"))
      )
    })

    plan_obj <- eventReactive(input$run_plan, {
      nt <- app_state$n_target
      bad <- is.null(nt) || length(nt) == 0 ||
             !is.finite(suppressWarnings(as.numeric(nt)[1]))
      if (bad) {
        showNotification("Compute an N balance first (and push N* to plan).",
                         type = "warning", duration = 5)
        return(NULL)
      }
      org_rows <- if (identical(input$org_fert, "None")) list()
        else list(list(
          fertilizer     = input$org_fert,
          quantity_t_ha  = as.numeric(input$org_q),
          year           = as.integer(input$org_year),
          modality_epoch = as.integer(input$org_modality),
          level          = input$org_level))
      min_rows <- if (identical(input$min_fert, "None")) list()
        else list(list(
          fertilizer     = input$min_fert,
          quantity_q_ha  = as.numeric(input$min_q),
          modality_epoch = as.integer(input$min_epoch)))

      withProgress(message = "Building plan...", value = 0.5, {
        tryCatch(agrinutri::plan_distribution(
          soil_group   = "Loamy textures",
          n_balance    = as.numeric(app_state$n_target),
          p_balance    = as.numeric(app_state$p_target %||% 0),
          k_balance    = as.numeric(app_state$k_target %||% 0),
          organic_rows = org_rows,
          mineral_rows = min_rows,
          zvn          = isTRUE(input$zvn)
        ), error = function(e) {
          showNotification(conditionMessage(e), type = "error",
                           duration = 10); NULL
        })
      })
    })
    `%||%` <- function(a, b) if (is.null(a)) b else a

    output$alerts_box <- renderUI({
      p <- plan_obj(); req(p)
      alerts <- p$alerts %||% character()
      zvn    <- p$zvn_alert %||% ""
      cls <- if (length(alerts) == 0 && !nzchar(zvn))
        "agrinutri-alert agrinutri-alert-ok" else "agrinutri-alert agrinutri-alert-warn"
      tags$div(class = cls,
        tags$strong(if (length(alerts) == 0 && !nzchar(zvn))
                      "Plan compliant." else "Plan alerts:"),
        tags$br(), paste(c(alerts, zvn), collapse = " \u2022 "))
    })

    output$split_plot <- renderPlot({
      p <- plan_obj(); req(p)
      df <- if (is.data.frame(p$plan)) p$plan else
            as.data.frame(p$plan, stringsAsFactors = FALSE)
      n_col <- NULL
      for (nm in c("N_applied", "N_kg_ha", "N_kg", "N"))
        if (nm %in% names(df)) { n_col <- nm; break }
      if (is.null(n_col)) {
        # fallback: try to compute from quantity*efficiency if present
        applied_org <- input$org_q * 2   # crude proxy 2 kg N per m3 slurry
        applied_min <- input$min_q * 46  # crude proxy urea 46%
      } else {
        kind_col <- intersect(c("source", "fertilizer", "kind", "type"),
                              names(df))[1]
        if (is.na(kind_col)) {
          applied_org <- sum(df[[n_col]][seq_len(1)])
          applied_min <- sum(df[[n_col]][-seq_len(1)])
        } else {
          is_org <- grepl("liqua|letam|digest|organic|bovin|suin|compost",
                           tolower(df[[kind_col]]))
          applied_org <- sum(df[[n_col]][is_org],  na.rm = TRUE)
          applied_min <- sum(df[[n_col]][!is_org], na.rm = TRUE)
        }
      }
      .agrinutri_plan_stack(
        applied_organic = applied_org,
        applied_mineral = applied_min,
        n_target = as.numeric(app_state$n_target),
        mas_cap  = app_state$mas_cap %||% NA,
        zvn      = 170)
    })

    output$plan_dt <- DT::renderDT({
      p <- plan_obj(); req(p)
      df <- if (is.data.frame(p$plan)) p$plan else
            as.data.frame(p$plan, stringsAsFactors = FALSE)
      DT::datatable(df, rownames = FALSE,
                    options = list(dom = "tp", pageLength = 10))
    })

    output$dl_csv <- downloadHandler(
      filename = function()
        sprintf("agrinutri_plan_%s.csv",
                format(Sys.time(), "%Y%m%d_%H%M")),
      content  = function(file) {
        p <- plan_obj()
        df <- if (!is.null(p) && is.data.frame(p$plan)) p$plan
              else data.frame()
        utils::write.csv(df, file, row.names = FALSE)
      }
    )

    observe({
      app_state$plan_obj <- plan_obj()
    })
  })
}
