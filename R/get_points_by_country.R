get_points_by_country <- function(
  points,
  countries,
  shp_filename
){

  country_shps_tbl <- make_country_shps(
    countries = countries
  )

  country_shps_v <- vect(country_shps_tbl$shp)
  values(country_shps_v) <- country_shps_tbl |> pull(countries)

  writeVector(
    country_shps_v,
    filename = shp_filename,
    overwrite = TRUE
  )

  country_shps_svc <- svc(country_shps_tbl$shp)
  names(country_shps_svc) <- country_shps_tbl |> pull(countries)


  map(
    .x = country_shps_svc,
    .f = select_points,
    points = points
  )

}
