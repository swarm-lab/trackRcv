shinyWidgets::verticalTabPanel(
  title = "1",
  box_height = "100%",
  shiny::p("Player module", class = "module-title"),
  shiny::hr(),
  shiny::htmlOutput("video_status"),
  shiny::htmlOutput("tracks_status"),

  shiny::tags$table(
    shiny::tags$tr(
      shiny::tags$td(
        shinyFiles::shinyFilesButton(
          "video_file",
          "Select video",
          "Please select a video file",
          FALSE,
          class = "fullWidth"
        ),
        style = "width: 49%;"
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shinyFiles::shinyFilesButton(
          "tracks_file",
          "Select tracks",
          "Please select a track file",
          FALSE,
          class = "fullWidth"
        ),
        style = "width: 49%;"
      )
    ),

    class = "stateTable"
  ),

  shiny::hr(),

  shiny::tags$table(
    shiny::tags$tr(
      shiny::tags$td(
        shiny::numericInput(
          "line_width_x",
          "Line width (pixels):",
          4,
          0,
          NA,
          1,
          "100%"
        ),
        style = "width: 49%;"
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shiny::numericInput(
          "outline_width_x",
          "Outline width (pixels):",
          2,
          0,
          NA,
          1,
          "100%"
        ),
        style = "width: 49%;"
      )
    ),
    shiny::tags$tr(
      shiny::tags$td(
        shiny::numericInput(
          "track_length_x",
          "Track length (frames):",
          30,
          0,
          NA,
          1,
          "100%"
        ),
        style = "width: 49%;"
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shiny::numericInput(
          "tag_scale_x",
          "Tag scale:",
          1.0,
          0,
          NA,
          .1,
          "100%"
        ),
        style = "width: 49%;"
      )
    ),
    class = "settingsTable"
  ),

  shiny::tags$table(
    shiny::tags$tr(
      shiny::tags$td(
        shiny::tags$p(shiny::tags$b("Show:")),
        style = "width: 24%; vertical-align: top;"
      ),
      shiny::tags$td(
        shinyWidgets::prettyToggle(
          inputId = "show_id",
          label_on = "IDs",
          label_off = "IDs",
          value = TRUE,
          shape = "curve",
          outline = TRUE,
          bigger = TRUE,
          width = "100%"
        ),
        style = "width: 24%;"
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shinyWidgets::prettyToggle(
          inputId = "show_boxes",
          label_on = "Boxes",
          label_off = "Boxes",
          value = TRUE,
          shape = "curve",
          outline = TRUE,
          bigger = TRUE,
          width = "100%"
        ),
        style = "width: 24%; "
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shinyWidgets::prettyToggle(
          inputId = "show_tracks",
          label_on = "Tracks",
          label_off = "Tracks",
          value = TRUE,
          shape = "curve",
          outline = TRUE,
          bigger = TRUE,
          width = "100%"
        ),
        style = "width: 24%; "
      )
    ),

    class = "stateTable",
    style = "margin-top: 10px; margin-bottom: -10px"
  ),

  shiny::hr(),

  shinyFiles::shinySaveButton(
    "export_video",
    "Export video",
    "Save video as...",
    filetype = "mp4",
    class = "fullWidth"
  ),

  shiny::hr()
)
