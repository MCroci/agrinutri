# modules/welcome.R
# Landing page with a short intro and one-click navigation to the main tabs.

welcomeUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(column(10, offset = 1,
      .agrinutri_card(
        h2(tags$strong("Transparent, balance-based N, P and K management")),
        p(class = "agrinutri-lead",
          "agrinutri computes legally-compliant field N, P and K doses from the",
          "Emilia-Romagna DPI 2026 balance, splits them into organic and",
          "mineral applications, and -- when a Sentinel-2 scene or UAV",
          "multispectral raster is available -- redistributes the N target",
          "pixel-by-pixel while preserving the balance at the field scale."),
        p("Use the tabs above to move through the workflow, or start here:"),
        fluidRow(
          column(4, actionButton(ns("go_nbal"),
            tagList(icon("leaf"), " New N balance"),
            class = "btn btn-lg btn-primary agrinutri-btn-cta", width = "100%")),
          column(4, actionButton(ns("go_plan"),
            tagList(icon("truck"), " Distribution plan"),
            class = "btn btn-lg btn-default agrinutri-btn-cta", width = "100%")),
          column(4, actionButton(ns("go_prec"),
            tagList(icon("satellite"), " Variable-rate + NNI"),
            class = "btn btn-lg btn-default agrinutri-btn-cta", width = "100%"))
        ),
        tags$hr(),
        h4("What happens behind each button"),
        tags$ul(
          tags$li(tags$strong("New N balance: "),
                  "enter the crop, expected yield and soil analysis, pick a",
                  "previous crop and the organic-legacy pattern. Returns the",
                  "field-scale N target and the full breakdown of the ten",
                  "balance terms."),
          tags$li(tags$strong("Distribution plan: "),
                  "takes the N (and optionally P, K) target and splits it",
                  "into pre-sowing organic + in-season mineral, enforcing the",
                  "170 kg N ha\u207B\u00B9 ZVN ceiling and crop-specific MAS."),
          tags$li(tags$strong("Variable-rate + NNI: "),
                  "upload an NDVI / NDRE raster to get a pixel-level VRT map",
                  "or run the GPR-based NNI pipeline on a Sentinel-2 L2A scene.")
        )
      )
    ))
  )
}

welcomeServer <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$go_nbal, updateNavbarPage(parent_session, "agrinutri_nav",
                                                 selected = "N balance"))
    observeEvent(input$go_plan, updateNavbarPage(parent_session, "agrinutri_nav",
                                                 selected = "Distribution plan"))
    observeEvent(input$go_prec, updateNavbarPage(parent_session, "agrinutri_nav",
                                                 selected = "Precision N"))
  })
}
