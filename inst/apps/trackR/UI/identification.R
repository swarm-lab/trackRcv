shinyjs::disabled(
  shinyWidgets::verticalTabPanel(
    title = "5",
    box_height = "100%",
    shiny::p("Identification module", class = "module-title"),
    shiny::hr(),

    shiny::tags$table(
      style = "margin-bottom: -15px",
      shiny::tags$tr(
        shiny::tags$td(
          shiny::actionButton(
            "auto_params",
            "Auto parameters",
            width = "100%"
          ),
          style = "width: 54%; vertical-align: top; padding: 0px;"
        ),
        shiny::tags$td(
          shiny::HTML("&nbsp;using&nbsp;"),
          style = "vertical-align: top; padding-top: 7px; text-align: center;"
        ),
        shiny::tags$td(
          shinyWidgets::autonumericInput(
            "n_ID_frames_x",
            NULL,
            100,
            "100%",
            decimalPlaces = 0,
            currencySymbol = " frames",
            currencySymbolPlacement = "s",
            minimumValue = 1,
            wheelStep = 1
          ),
          style = "width: 36%; padding-top: 0px; "
        )
      )
    ),

    shiny::hr(),
    shiny::numericInput(
      "blob_width_x",
      "Maximum width (in pixels)",
      0,
      min = 1,
      max = Inf,
      step = 1,
      width = "100%"
    ),
    shiny::numericInput(
      "blob_height_x",
      "Maximum height (in pixels)",
      0,
      min = 1,
      max = Inf,
      step = 1,
      width = "100%"
    ),
    shiny::numericInput(
      "blob_area_x",
      "Minimum area (in pixels)",
      0,
      min = 1,
      max = Inf,
      step = 1,
      width = "100%"
    ),
    shiny::numericInput(
      "blob_density_x",
      "Minimum density [0-1]",
      0,
      min = 0,
      max = 1,
      step = 0.01,
      width = "100%"
    ),
    shiny::hr()
  )
)
