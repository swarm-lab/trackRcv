  shinyWidgets::verticalTabsetPanel(
    id = "bookmarking",
    contentWidth = 11,
    menuSide = "right",
    
    verticalTabPanel(
      title = "X",
      box_height = "100%",
    
      tags$table(
        tags$tr(
          tags$td(
            shinySaveButton(
              "save_state",
              "Save state",
              "Save state as...",
              filetype = list(R = c("Rds", "rds")),
              class = "fullWidth"
            ),
            style = "width: 49%;"
          ),
          tags$td(),
          tags$td(
            shinyFilesButton(
              "load_state",
              "Load state",
              "Please select a state file",
              FALSE,
              class = "fullWidth"
            ),
            style = "width: 49%;"
          )
        ),
    
        tags$tr(),
    
        tags$tr(
          tags$td(
            colspan = "3",
            actionButton("reset_x", "Reset state", width = "100%")
          )
        ),
    
        class = "stateTable"
      ),
    
      p()
    )
  )
