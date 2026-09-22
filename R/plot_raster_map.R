# raster map with optional points overlaid, no legend
plot_raster_map <- function(
    rast,
    points = NULL,
    point_col = "deeppink"
){

  p <- ggplot() +
    geom_spatraster(data = rast)

  if (!is.null(points)) {
    p <- p +
      geom_spatvector(
        data = points,
        col = point_col
      )
  }

  p +
    theme_void() +
    theme(legend.position = "none") +
    scale_fill_viridis_c(
      option = "G",
      begin = 1,
      end = 0,
      na.value = "white"
    )

}
