# raster background with points coloured by data_type
plot_data_type_map <- function(
    background,
    pts,
    colours,
    fill_end = 0
){

  ggplot() +
    geom_spatraster(
      data = background
    ) +
    geom_spatvector(
      data = pts,
      aes(
        col = data_type
      )
    ) +
    scale_fill_viridis_c(
      option = "G",
      begin = 1,
      end = fill_end,
      na.value = "white",
      guide = "none"
    ) +
    scale_colour_manual(
      values = colours,
      guide = guide_legend(title = "Data type")
    ) +
    theme_void() +
    theme(
      legend.position = "inside",
      legend.position.inside = c(0.25, 0.4)
    )

}
