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

  shiny::p(shiny::strong("Keyboard navigation")),

  shiny::tags$table(
    style = "width: 100%; text-align: center;",
    shiny::tags$tr(
      shiny::tags$td(),
      shiny::tags$td("+ 1 sec.", style = "vertical-align: bottom;"),
      shiny::tags$td()
    ),
    shiny::tags$tr(
      shiny::tags$td("- 1 frame", style = "vertical-align: bottom;"),
      shiny::tags$td(
        shiny::actionButton(
          "plus_sec",
          shiny::icon(
            "caret-up",
            class = "fa-solid",
            style = "font-size: 30px; color: #c8c8c8;"
          ),
          class = "fullWidth",
          style = "padding: 0px;"
        )
      ),
      shiny::tags$td("+ 1 frame", style = "vertical-align: bottom;")
    ),
    shiny::tags$tr(
      shiny::tags$td(
        shiny::actionButton(
          "minus_frame",
          shiny::icon(
            "caret-left",
            class = "fa-solid",
            style = "font-size: 30px; color: #c8c8c8;"
          ),
          class = "fullWidth",
          style = "padding: 0px;"
        )
      ),
      shiny::tags$td(
        shiny::actionButton(
          "minus_sec",
          shiny::div(
            shiny::div(shiny::icon(
              "caret-down",
              class = "fa-solid",
              style = "font-size: 30px; color: #c8c8c8;"
            ))
          ),
          class = "fullWidth",
          style = "padding: 0px;"
        )
      ),
      shiny::tags$td(
        shiny::actionButton(
          "plus_frame",
          shiny::icon(
            "caret-right",
            class = "fa-solid",
            style = "font-size: 30px; color: #c8c8c8;"
          ),
          class = "fullWidth",
          style = "padding: 0px;"
        )
      )
    ),
    shiny::tags$tr(
      shiny::tags$td(),
      shiny::tags$td("- 1 sec.", style = "vertical-align: top;"),
      shiny::tags$td()
    )
  ),

  shiny::hr(),

  shiny::tags$table(
    shiny::tags$tr(
      shiny::tags$td(
        shinyWidgets::awesomeRadio(
          inputId = "show_id",
          label = "Show IDs",
          choices = c("Yes", "No"),
          selected = "Yes",
          inline = TRUE,
          checkbox = TRUE,
          width = "100%"
        ),
        style = "width: 49%; text-align:center;"
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shinyWidgets::awesomeRadio(
          inputId = "show_tracks",
          label = "Show tracks",
          choices = c("Yes", "No"),
          selected = "Yes",
          inline = TRUE,
          checkbox = TRUE,
          width = "100%"
        ),
        style = "width: 49%; text-align:center;"
      )
    ),

    class = "stateTable"
  ),

  shiny::hr(),

  shiny::tags$table(
    shiny::tags$tr(
      shiny::tags$td(
        shiny::numericInput(
          "track_width_x",
          "Track width (pixels):",
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
          "track_length_x",
          "Track length (frames):",
          30,
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
          "tag_scale_x",
          "Tag scale:",
          1.5,
          0,
          NA,
          .1,
          "100%"
        ),
        style = "width: 49%;"
      ),
      shiny::tags$td(),
      shiny::tags$td(
        shiny::numericInput(
          "tag_width_x",
          "Tag line width:",
          4,
          0,
          NA,
          1,
          "100%"
        ),
        style = "width: 49%;"
      )
    ),
    class = "settingsTable"
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
