shinyWidgets::verticalTabPanel(
  title = "1",
  box_height = "100%",
  shiny::p("Fixer module", class = "module-title"),
  shiny::hr(),
  shiny::htmlOutput("video_status"),
  shiny::htmlOutput("tracks_status"),

  tags$table(
    tags$tr(
      tags$td(
        shinyFiles::shinyFilesButton(
          "video_file",
          "Select video",
          "Please select a video file",
          FALSE,
          class = "fullWidth"
        ),
        style = "width: 49%;"
      ),
      tags$td(),
      tags$td(
        shinyFilesButton(
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

  tags$table(
    style = "width: 100%; text-align: center;",
    tags$tr(
      tags$td(),
      tags$td("+ 1 sec.", style = "vertical-align: bottom;"),
      tags$td()
    ),
    tags$tr(
      tags$td("- 1 frame", style = "vertical-align: bottom;"),
      tags$td(
        actionButton(
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
      tags$td("+ 1 frame", style = "vertical-align: bottom;")
    ),
    tags$tr(
      tags$td(
        actionButton(
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
      tags$td(
        actionButton(
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
      tags$td(
        actionButton(
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
    tags$tr(
      tags$td(),
      tags$td("- 1 sec.", style = "vertical-align: top;"),
      tags$td()
    )
  ),

  shiny::hr(),

  shiny::tags$table(
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
      tags$td(),
      tags$td(
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

  tags$table(
    tags$tr(
      tags$td(
        actionButton("reassign_track", "Reassign [q]", width = "100%"),
        style = "width: 49%;"
      ),
      tags$td(),
      tags$td(
        actionButton("remove_track", "Remove [w]", width = "100%"),
        style = "width: 49%;"
      )
    ),

    tags$tr(),

    tags$tr(
      tags$td(
        actionButton("swap_track", "Swap IDs [e]", width = "100%"),
        style = "width: 49%;"
      ),
      tags$td(),
      tags$td(
        actionButton("merge_track", "Merge IDs [r]", width = "100%"),
        style = "width: 49%;"
      )
    ),

    tags$tr(),

    tags$tr(
      tags$td(
        actionButton("revert_changes", "Undo [a]", width = "100%"),
        style = "width: 49%;"
      ),
      tags$td(),
      tags$td(
        actionButton("save_changes", "Save [s]", width = "100%"),
        style = "width: 49%;"
      )
    ),

    class = "stateTable"
  ),

  hr(),

  tableOutput("track_stats"),

  shiny::hr()
)
