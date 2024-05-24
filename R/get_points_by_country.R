get_points_by_country <- function(
  points, shps
){

  map(
    .x = shps,
    .f = select_points,
    points = points
  )

}
