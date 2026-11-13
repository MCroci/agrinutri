# modules/pkbalance.R
# Phosphorus and potassium balances (DPI 2026, Mantenimento/Arricchimento/Riduzione).

pkBalanceUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(6,
      .agrinutri_card(
        h3(icon("flask"), " P balance"),
        selectInput(ns("p_crop"), "Crop",
                    choices = .agrinutri_crop_choices(),
                    selected = .agrinutri_default_crop()),
        fluidRow(
          column(6, numericInput(ns("p_yield"),
                                  "Expected yield (t ha\u207B\u00B9)",
                                  60, min = 0.1, step = 1)),
          column(6, numericInput(ns("p_olsen"),
                                  "Olsen P (ppm)", 25, min = 0, step = 1))
        ),
        fluidRow(
          column(4, numericInput(ns("p_sand"), "Sand (%)",
                                  50, min = 0, max = 100)),
          column(4, numericInput(ns("p_clay"), "Clay (%)",
                                  35, min = 0, max = 100)),
          column(4, selectInput(ns("p_unit"), "Olsen unit",
                                  choices = c("P2O5", "P"),
                                  selected = "P2O5"))
        ),
        actionButton(ns("p_run"), "Compute P balance",
                     class = "btn btn-primary", icon = icon("play")),
        tags$hr(),
        uiOutput(ns("p_summary")),
        DT::DTOutput(ns("p_terms"))
      )
    ),
    column(6,
      .agrinutri_card(
        h3(icon("flask"), " K balance"),
        selectInput(ns("k_crop"), "Crop",
                    choices = .agrinutri_crop_choices(),
                    selected = .agrinutri_default_crop()),
        fluidRow(
          column(6, numericInput(ns("k_yield"),
                                  "Expected yield (t ha\u207B\u00B9)",
                                  60, min = 0.1, step = 1)),
          column(6, numericInput(ns("k_value"),
                                  "Exchangeable K (ppm)", 150,
                                  min = 0, step = 5))
        ),
        fluidRow(
          column(4, numericInput(ns("k_sand"), "Sand (%)",
                                  50, min = 0, max = 100)),
          column(4, numericInput(ns("k_clay"), "Clay (%)",
                                  35, min = 0, max = 100)),
          column(4, selectInput(ns("k_unit"), "K unit",
                                  choices = c("K2O", "K"),
                                  selected = "K2O"))
        ),
        actionButton(ns("k_run"), "Compute K balance",
                     class = "btn btn-primary", icon = icon("play")),
        tags$hr(),
        uiOutput(ns("k_summary")),
        DT::DTOutput(ns("k_terms"))
      )
    ),
    column(12,
      div(style = "text-align:center; margin-top:14px;",
          actionButton(ns("push_pk"),
            tagList(icon("arrow-right"),
                    " Send P* and K* to Distribution plan"),
            class = "btn btn-success btn-lg"))
    )
  )
}

pkBalanceServer <- function(id, research_mode, app_state) {
  moduleServer(id, function(input, output, session) {

    pbal <- eventReactive(input$p_run, {
      tryCatch(agrinutri::P_balance(
        crop = input$p_crop,
        expected_yield_tons_ha = input$p_yield,
        olsen_value = input$p_olsen,
        olsen_unit  = input$p_unit,
        sand = input$p_sand, clay = input$p_clay
      ), error = function(e) {
        showNotification(conditionMessage(e), type = "error",
                         duration = 10); NULL
      })
    })

    kbal <- eventReactive(input$k_run, {
      tryCatch(agrinutri::K_balance(
        crop = input$k_crop,
        expected_yield_tons_ha = input$k_yield,
        k_value = input$k_value,
        k_unit  = input$k_unit,
        sand = input$k_sand, clay = input$k_clay
      ), error = function(e) {
        showNotification(conditionMessage(e), type = "error",
                         duration = 10); NULL
      })
    })

    make_summary <- function(b, target_name) {
      if (is.null(b)) return(NULL)
      nm <- grep(paste0("^", target_name, "_required$"),
                 names(b), value = TRUE)
      val <- if (length(nm)) b[[nm]] else
             tryCatch(b[[paste0(target_name, "_required")]],
                      error = function(e) NA)
      div(class = "agrinutri-kpi-row",
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value", .agrinutri_fmt(val, 0)),
              span(class = "agrinutri-kpi-label",
                   paste0(target_name, " to apply (kg ha\u207B\u00B9)"))),
          div(class = "agrinutri-kpi",
              span(class = "agrinutri-kpi-value",
                   as.character(b$strategy %||% "--")),
              span(class = "agrinutri-kpi-label", "Strategy")))
    }
    `%||%` <- function(a, b) if (is.null(a)) b else a

    output$p_summary <- renderUI(make_summary(pbal(), "P2O5"))
    output$k_summary <- renderUI(make_summary(kbal(), "K2O"))

    output$p_terms <- DT::renderDT({
      b <- pbal(); req(b)
      df <- data.frame(term = names(b), value = unlist(lapply(b,
        function(x) if (is.numeric(x)) round(x, 2) else as.character(x))),
        stringsAsFactors = FALSE, row.names = NULL)
      DT::datatable(df, rownames = FALSE,
                    options = list(dom = "t", paging = FALSE,
                                   ordering = FALSE))
    })
    output$k_terms <- DT::renderDT({
      b <- kbal(); req(b)
      df <- data.frame(term = names(b), value = unlist(lapply(b,
        function(x) if (is.numeric(x)) round(x, 2) else as.character(x))),
        stringsAsFactors = FALSE, row.names = NULL)
      DT::datatable(df, rownames = FALSE,
                    options = list(dom = "t", paging = FALSE,
                                   ordering = FALSE))
    })

    observeEvent(input$push_pk, {
      p <- pbal(); k <- kbal()
      if (is.null(p) && is.null(k)) {
        showNotification("Compute at least one balance first.",
                         type = "warning", duration = 4); return()
      }
      if (!is.null(p)) {
        app_state$p_bal_obj <- p
        app_state$p_target  <- p$P2O5_required %||% NA
      }
      if (!is.null(k)) {
        app_state$k_bal_obj <- k
        app_state$k_target  <- k$K2O_required %||% NA
      }
      showNotification("P* and K* sent to Distribution plan tab.",
                       type = "message", duration = 3)
    })
  })
}
