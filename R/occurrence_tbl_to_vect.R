occurrence_tbl_to_vect <- function(x, crs = "EPSG:4326"){

  vect(
    x,
    geom = c("x", "y"),
    crs = crs
  )

}
