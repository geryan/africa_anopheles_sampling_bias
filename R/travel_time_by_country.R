travel_time_by_country <- function(
    friction_surface,
    countries
){

  countries <- tt_countries[c(3, 23, 53)]

  tibble::tibble(countries) |>
    dplyr::mutate(
      shp = purrr::map(
        .x = countries,
        .f = function(x){
          malariaAtlas::getShp(
            ISO = x
           ) |>
            sf::st_make_valid() |>
            sf::st_union() |>
            terra::vect() |>
            terra::fillHoles()
        }
      ),
      fs = purrr::map(
        .x = shp,
        .f = function(x){
          traveltime::get_friction_surface(
            surface = "motor2020",
            file_name = temptif(),
            overwrite = TRUE,
            extent = x
          ) |>
            mask(mask = x)
        }
      ),
      tt = purrr::map(
        .x = fs
      )
    )

}

