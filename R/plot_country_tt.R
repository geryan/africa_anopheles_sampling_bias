plot_country_tt <- function(iso3, tt, country_shps_v){

  plot_raster_map(
    mask_to_country(tt, country_shps_v, iso3)
  )

}
