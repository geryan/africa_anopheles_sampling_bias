get_country_shps <- function(countries){

  z <- tibble(countries) |>
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

  x <- vect(z$shp)

  values(x) <- z[,1]

  x

}
