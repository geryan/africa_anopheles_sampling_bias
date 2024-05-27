make_country_shps <- function(countries){

  tibble(countries) |>
    mutate(
      shp = map(
        .x = countries,
        .f = function(x){
          getShp(
            ISO = x
          ) |>
            st_make_valid() |>
            st_union() |>
            vect() |>
            fillHoles()
        }
      )
    )

}
