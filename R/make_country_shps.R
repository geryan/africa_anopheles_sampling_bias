make_country_shps <- function(countries){

  tibble(countries) |>
    mutate(
      shp = map(
        .x = countries,
        .f = function(x){
          shp <- getShp(
            ISO = x
          ) |>
            st_make_valid() |>
            st_union()

          # st_make_valid can leave stray lines/points (e.g. Seychelles), so st_union
          # returns a GEOMETRYCOLLECTION that vect() splits into one row per polygon.
          # Keep only the polygons so each country is a single row.
          if(st_is(shp, "GEOMETRYCOLLECTION")){
            shp <- shp |>
              st_collection_extract("POLYGON") |>
              st_union()
          }

          shp |>
            vect() |>
            fillHoles()
        }
      )
    )

}
