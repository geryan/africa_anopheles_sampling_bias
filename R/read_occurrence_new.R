# vector atlas point locations: one row per record, with species and data
# type (po presence-only, pa presence-absence, count)
read_occurrence_new <- function(file){

  read_csv(file, show_col_types = FALSE) |>
    select(species, data_type, x = longitude, y = latitude) |>
    filter(!is.na(x) & !is.na(y))

}
