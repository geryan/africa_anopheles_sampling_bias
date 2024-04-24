point_tbl_to_vect <- function(x, crs = "EPSG:4326"){
  x |>
    as.matrix() |>
    vect(crs = crs)
}
