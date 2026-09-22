plot_country_tt_pts <- function(iso3, tt, country_shps_v, pts){

  plot_data_type_map(
    mask_to_country(tt, country_shps_v, iso3),
    mask_to_country(pts, country_shps_v, iso3),
    # named so colours stay consistent if a country lacks one data type
    colours = c(
      "Research\nfacility" = "deeppink",
      "Vector\noccurrence" = "gold"
    )
  ) +
    theme(
      legend.position = "bottom",
      plot.margin = margin(5, 5, 15, 5)
    )

}
