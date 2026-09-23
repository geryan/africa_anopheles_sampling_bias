# number of occurrence records, mean travel time, and land area (km2, area of
# native cells with travel time values) per aggregated cell
make_tt_occ_data <- function(tt, occ_pts, agg_fact = 10){

  # records per native cell, zero where there are none
  counts <- rasterize(
    occ_pts,
    tt,
    fun = "length",
    background = 0
  )

  tt_agg <- aggregate(tt, fact = agg_fact, fun = "mean", na.rm = TRUE)

  counts_agg <- aggregate(counts, fact = agg_fact, fun = "sum", na.rm = TRUE) |>
    mask(tt_agg)

  area_agg <- cellSize(tt, unit = "km", mask = TRUE) |>
    aggregate(fact = agg_fact, fun = "sum", na.rm = TRUE) |>
    mask(tt_agg)

  c(tt_agg, counts_agg, area_agg) |>
    as.data.frame(na.rm = TRUE) |>
    setNames(c("tt", "count", "area_km2")) |>
    as_tibble()

}
