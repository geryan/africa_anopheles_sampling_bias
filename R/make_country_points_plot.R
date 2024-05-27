make_country_points_plot <- function(country_shps_v){

  idemcols <- idem(7)[c(7,4)]

  ggplot(country_shps_v) +
    geom_spatvector(
      aes(
        fill = npoints
      )
    ) +
    theme_minimal() +
    scale_fill_gradient(
      low = idemcols[1],
      high = idemcols[2]
    )


}
