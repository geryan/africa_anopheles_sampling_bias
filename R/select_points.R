select_points <- function(points, pol){

  point_tbl <- points |>
    point_tbl_to_vect() |>
    terra::extract(
      x = pol,
      y = _
    )

  z <- points[!is.nan(point_tbl[,2]),]

  z

}
