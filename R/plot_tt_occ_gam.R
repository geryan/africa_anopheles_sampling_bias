# log_x puts travel time on a log1p scale, useful over the full range where
# the decline is squashed against zero. log_y puts records per cell on a log10
# scale, with y_min_log as the lower limit. on a linear y scale, the axis is
# capped at the upper CI at the peak of the fitted curve, so the very wide CI
# where data are sparse doesn't swamp the plot. tt_occ_obs, if not NULL, adds
# observed records per 100 km2 by travel time bin (from bin_tt_occ()), and
# errorbars adds bars to them: "percentile" for the 5th-95th percentiles of
# per-cell rates, "ci90" for the 90% CI of the rate, or "none". y_max
# overrides the upper y limit; anything beyond it is clipped
plot_tt_occ_gam <- function(
    tt_occ_pred,
    tt_occ_obs = NULL,
    errorbars = c("none", "percentile", "ci90"),
    log_x = FALSE,
    log_y = FALSE,
    y_min_log = 1e-4,
    y_max = NULL
){

  errorbars <- match.arg(errorbars)

  if (is.null(y_max)) {
    y_max <- tt_occ_pred$upper[which.max(tt_occ_pred$fit)]

    if (!is.null(tt_occ_obs)) {
      y_max <- max(y_max, tt_occ_obs$rate)
    }
  }

  max_tt <- tt_occ_pred$max_tt[1]

  p <- ggplot(tt_occ_pred, aes(x = tt)) +
    geom_ribbon(
      aes(ymin = lower, ymax = upper),
      fill = "grey70"
    ) +
    geom_line(aes(y = fit))

  if (!is.null(tt_occ_obs) && errorbars != "none") {
    bar_limits <- switch(
      errorbars,
      percentile = aes(ymin = q05, ymax = q95),
      ci90 = aes(ymin = ci90_lower, ymax = ci90_upper)
    )

    p <- p +
      geom_errorbar(
        data = tt_occ_obs,
        bar_limits,
        col = data_type_colours()[["Old records"]],
        width = 0
      )
  }

  if (!is.null(tt_occ_obs)) {
    p <- p +
      geom_point(
        data = tt_occ_obs |>
          filter(!log_y | rate > 0),
        aes(y = rate),
        col = data_type_colours()[["Old records"]]
      )
  }

  p <- p +
    labs(
      x = "Travel time from a research location (minutes)",
      y = expression("Number of occurrence records per 100 km"^2)#,
      # subtitle = sprintf(
      #   "smooth on %s travel time, cells up to %s",
      #   ifelse(tt_occ_pred$smooth[1] == "log1p", "log(1 + x)", "raw"),
      #   ifelse(is.finite(max_tt), paste(max_tt, "minutes"), "full range")
      # )
    ) +
    theme_bw()

  if (log_x) {
    p <- p +
      scale_x_continuous(
        transform = "log1p",
        breaks = c(0, 10, 30, 100, 300, 1000, 3000, 10000)
      )
  }

  if (log_y) {
    p +
      scale_y_log10() +
      coord_cartesian(ylim = c(y_min_log, y_max))
  } else {
    p +
      coord_cartesian(ylim = c(0, y_max))
  }

}
