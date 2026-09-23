# travel time map with land with travel time above max_tt shown in grey.
# land_v is a polygon of the land area, drawn in grey underneath the raster.
# limits sets the colour scale range; defaults to 0 to max_tt, pass the range
# of another map to match its colours
plot_tt_capped <- function(
    tt,
    land_v,
    max_tt = 180,
    limits = c(0, max_tt),
    over_col = "#5B6770"
){

  ggplot() +
    geom_spatvector(
      data = land_v,
      fill = over_col,
      col = NA
    ) +
    geom_spatraster(
      data = ifel(tt > max_tt, NA, tt)
    ) +
    theme_void() +
    theme(legend.position = "none") +
    scale_fill_viridis_c(
      option = "G",
      begin = 1,
      end = 0,
      limits = limits,
      na.value = "transparent"
    )

}
