read_country_shps <- function(
  country_shps_filename,
  points_per_country
) {


  v <- vect(country_shps_filename)

  v[["npoints"]] <- points_per_country$npoints

  v
}
