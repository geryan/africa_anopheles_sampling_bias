combine_point_types <- function(occ_pts, research_pts){

  research_pts$data_type <- "Research\nfacility"

  c(
    occ_pts |>
      mutate(data_type = "Vector\noccurrence") |>
      select(data_type),
    research_pts
  ) |>
    vect()

}
