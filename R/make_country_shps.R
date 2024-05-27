make_country_shps <- function(countries, filename = "outputs/country.shps.gpkg"){

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
  #x <- svc(z$shp)

  values(x) <- z |> pull(countries)
  #names(x) <- z |> pull(countries)

  writeVector(
    x,
    filename = filename,
    overwrite = TRUE
  )

}
