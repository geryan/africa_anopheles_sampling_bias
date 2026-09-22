save_plot <- function(
    plot,
    filename,
    width = 1600,
    height = 1600,
    units = "px",
    bg = "white"
){

  ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    units = units,
    bg = bg
  )

  filename

}
