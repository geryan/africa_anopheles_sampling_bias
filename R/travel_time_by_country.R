travel_time_by_country <- function(
    friction_surface,
    country_shps_v,
    points_per_country,
    travel_time_africa,
    country_points_list
){

  points_per_country |>
    mutate(
      r = map2(
        .x = country,
        .y = npoints,
        .f = function(x, y, fs, tt, shp, pl){

          if(y == 0){

            mask(
              x = tt,
              mask = shp |>
                filter(country == x)
            )

          } else {

            cfs <- mask(
              x = fs,
              mask = shp |>
                filter(country == x)
            )

            r <- calculate_travel_time(
              friction_surface = cfs,
              points = pl[[x]],
            )

            idx <- which(values(r) == Inf)

            r[idx] <- NA

            #crs(r) <- crs(tt)
            #ext(r) <- ext(tt)

            writereadrast(
              r,
              filename = sprintf(
                "outputs/tt_by_country/%s_.tif",
                x
              )
            )

          }

        },
        fs = friction_surface,
        tt = travel_time_africa,
        shp = country_shps_v,
        pl = country_points_list
      )
    ) |>
    pull(r) |>
    sprc() |>
    merge() |>
    writereadrast(
      filename = "outputs/travel_time_by_country.tif",
      overwrite = TRUE,
      layernames = "travel_time"
    )

}

