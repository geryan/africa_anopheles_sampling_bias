select_points <- function(points, poly){

  point_tbl <- points |>
    point_tbl_to_vect() |>
    terra::extract(
      x = poly,
      y = _
    )

  points[!is.nan(point_tbl[,2]),]

}
