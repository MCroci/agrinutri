# agrinutri Shiny app -- entry point.
#
# Run locally with:
#   shiny::runApp("inst/shinyapp")
# or via the package helper:
#   agrinutri::run_app()

source("global.R", local = TRUE)

# ---------- UI -------------------------------------------------------
ui <- navbarPage(
  id = "agrinutri_nav",
  title = div(
    tags$span("agrinutri", style = "font-weight: 700; letter-spacing: 0.5px;"),
    tags$span(sprintf(" v%s", APP_VERSION),
              style = "font-weight: 300; opacity: 0.7; font-size: 13px; margin-left: 4px;")
  ),
  windowTitle = "agrinutri -- Balance-based & sensor-based N management",
  theme = NULL,
  collapsible = TRUE,

  header = tagList(
    useShinyjs(),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      tags$link(rel = "icon", type = "image/png", href = "favicon.png")
    ),
    # Mode toggle - visible on every tab, top-right of the navbar
    absolutePanel(
      class = "agrinutri-mode-toggle",
      top = "10px", right = "14px", width = "auto",
      checkboxInput("research_mode",
                    label = "Research mode", value = FALSE, width = "auto")
    )
  ),

  tabPanel("Welcome",           icon = icon("home"),          welcomeUI("welcome")),
  tabPanel("N balance",         icon = icon("leaf"),          nBalanceUI("nbal")),
  tabPanel("P & K balance",     icon = icon("flask"),         pkBalanceUI("pkbal")),
  tabPanel("Distribution plan", icon = icon("truck"),         planUI("plan")),
  tabPanel("Precision N",       icon = icon("satellite"),     precisionUI("prec")),
  tabPanel("Spatial balance",   icon = icon("map"),           spatialUI("spat")),
  tabPanel("Farm / Azienda",    icon = icon("tractor"),       farmUI("farm")),

  tabPanel("About", icon = icon("circle-info"),
           fluidRow(column(10, offset = 1,
             div(class = "agrinutri-card",
               h3("About agrinutri"),
               p("agrinutri is an open-source R package that implements balance-based",
                 "and sensor-based nitrogen fertilisation planning. This web",
                 "interface exposes the core functionality of the package through",
                 "interactive forms and visualisations."),
               p(tags$strong("Reference parameterisation: "),
                 "Emilia-Romagna Integrated Production Guidelines (DPI 2026)."),
               p(tags$strong("Source code and documentation: "),
                 tags$a(href = "https://github.com/mcroci/agrinutri",
                        "https://github.com/mcroci/agrinutri")),
               p(tags$strong("Licence: "), "MIT."),
               tags$hr(),
               h4("Two working modes"),
               tags$ul(
                 tags$li(tags$strong("Agronomist view (default): "),
                         "clean forms, realtime validation of MAS and ZVN",
                         "constraints, single-click export of the fertilisation",
                         "plan. Designed for extension services and on-farm consulting."),
                 tags$li(tags$strong("Research view: "),
                         "all modules expose additional parameters (coefficient",
                         "overrides, intermediate balance terms, debug logs)",
                         "marked with the dashed gold border. Toggle the",
                         "\"Research mode\" switch at the top-right.")
               ),
               tags$hr(),
               div(class = "agrinutri-footer",
                   sprintf("agrinutri v%s -- build %s. ", APP_VERSION, APP_BUILD),
                   tags$a(href = "https://github.com/mcroci/agrinutri/issues",
                          "Report an issue"), " ",
                   tags$a(href = "https://github.com/mcroci/agrinutri",
                          "Source on GitHub"))
             )
           ))
  )
)

# ---------- Server ---------------------------------------------------
server <- function(input, output, session) {
  research_mode <- reactive(isTRUE(input$research_mode))

  app_state <- reactiveValues(
    n_target  = NULL, p_target = NULL, k_target = NULL,
    n_bal_obj = NULL, p_bal_obj = NULL, k_bal_obj = NULL,
    crop      = NULL, mas_cap  = NULL, plan_obj  = NULL
  )

  welcomeServer("welcome",   parent_session = session)
  nBalanceServer("nbal",     research_mode, app_state)
  pkBalanceServer("pkbal",   research_mode, app_state)
  planServer("plan",         research_mode, app_state)
  precisionServer("prec",    research_mode, app_state)
  spatialServer("spat",      research_mode, app_state)
  farmServer("farm",         research_mode, app_state)

  observeEvent(input$research_mode, ignoreInit = TRUE, {
    if (isTRUE(input$research_mode))
      showNotification(
        "Research mode enabled -- additional parameters and intermediate outputs are now visible.",
        type = "message", duration = 4)
  })
}

shinyApp(ui, server)
