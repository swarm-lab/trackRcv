# Globals and reactives
shinyjs::hideElement("curtain")
toggled_tabs <- data.table::data.table(
  tab = 1:7,
  toggled = c(TRUE, rep(FALSE, 6))
)

black_screen <- reticulate::r_to_py(array(0L, c(1080, 1920, 3)))
to_display <- NULL

refresh_display <- shiny::reactiveVal(0)
print_display <- shiny::reactiveVal(0)
