shinyjs::disabled(
  shinyWidgets::verticalTabPanel(
    title = "7",
    box_height = "100%",
    shiny::p("Tracking module", class = "module-title"),

    shiny::hr(),

    shiny::sliderInput(
      "look_back_x",
      "Look back (frames):",
      min = 1,
      max = 150,
      value = 5,
      width = "100%"
    ),

    shiny::sliderInput(
      "max_dist_x",
      "Maximum distance (pixels):",
      min = 1,
      max = 200,
      value = 30,
      width = "100%"
    ),

    shiny::hr(),

    shinyWidgets::awesomeRadio(
      inputId = "preview_tracks_x",
      label = "Preview tracks during tracking (slower)",
      choices = c("Yes", "No"),
      selected = "No",
      inline = TRUE,
      checkbox = TRUE,
      width = "100%"
    ),

    shiny::hr(),

    shinyFiles::shinySaveButton(
      "track_button",
      "Start tracking",
      "Save tracks as...",
      filetype = "csv",
      class = "fullWidth"
    ),

    shiny::hr()
  )
)
