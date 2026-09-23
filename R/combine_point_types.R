# research locations and occurrence points in one SpatVector, labelled by
# data_type. occ_pts_new, if given, is added as a third type. research
# locations go last so they are drawn on top of the occurrence points
combine_point_types <- function(occ_pts, research_pts, occ_pts_new = NULL){

  research_pts$data_type <- "Research\nfacility"

  pts <- list(
    occ_pts |>
      mutate(data_type = "Old records") |>
      select(data_type)
  )

  if (!is.null(occ_pts_new)) {
    pts <- c(
      pts,
      list(
        occ_pts_new |>
          mutate(data_type = "New records") |>
          select(data_type)
      )
    )
  }

  c(pts, list(research_pts)) |>
    do.call(what = c) |>
    vect()

}
