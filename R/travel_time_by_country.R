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

            calculate_travel_time(
              friction_surface = cfs,
              points = pl[[x]],
            )

          }

        },
        fs = friction_surface,
        tt = travel_time_africa,
        shp = country_shps_v,
        pl = country_points_list
      )
    )



  # countries <- tt_countries[c(3, 23, 53)]
  #
  # tibble::tibble(countries) |>
  #   dplyr::mutate(
  #     shp = purrr::map(
  #       .x = countries,
  #       .f = function(x){
  #         malariaAtlas::getShp(
  #           ISO = x
  #          ) |>
  #           sf::st_make_valid() |>
  #           sf::st_union() |>
  #           terra::vect() |>
  #           terra::fillHoles()
  #       }
  #     ),
  #     fs = purrr::map(
  #       .x = shp,
  #       .f = function(x){
  #         traveltime::get_friction_surface(
  #           surface = "motor2020",
  #           file_name = temptif(),
  #           overwrite = TRUE,
  #           extent = x
  #         ) |>
  #           mask(mask = x)
  #       }
  #     ),
  #     tt = purrr::map(
  #       .x = fs
  #     )
  #   )



}

