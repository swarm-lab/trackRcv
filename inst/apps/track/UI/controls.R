shiny::div(
  id = "controls",
  style = "width: 90%; margin: 0 auto; padding-bottom: 0px;",
  frame_position_range_ui(
    "fp",
    color = "#2b4e8d",
    pips = list(mode = "count", values = 5, density = 0)
  ),
  shinyjs::hidden(
    shiny::div(
      id = "controls_legend",
      style = "padding-bottom: 10px;",
      shiny::span("-1 second"),
      shiny::icon(
        "square-caret-down",
        class = "fa-regular",
        style = "font-size: 16px; vertical-align: bottom;"
      ),
      shiny::span(" | "),
      shiny::span("-1 frame"),
      shiny::icon(
        "square-caret-left",
        class = "fa-regular",
        style = "font-size: 16px; vertical-align: bottom;"
      ),
      shiny::span(" | "),
      shiny::span("+1 frame"),
      shiny::icon(
        "square-caret-right",
        class = "fa-regular",
        style = "font-size: 16px; vertical-align: bottom;"
      ),
      shiny::span(" | "),
      shiny::span("+1 second"),
      shiny::icon(
        "square-caret-up",
        class = "fa-regular",
        style = "font-size: 16px; vertical-align: bottom;"
      )
    )
  )
)
