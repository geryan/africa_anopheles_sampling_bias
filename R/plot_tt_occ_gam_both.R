# as plot_tt_occ_gam(), but with one curve, band and set of observed rates
# per dataset, coloured by dataset. preds and obs are named lists (names are
# the data types, matching data_type_colours()), obs may be NULL
plot_tt_occ_gam_both <- function(
    preds,
    obs = NULL,
    errorbars = c("none", "percentile", "ci90"),
    dodge = 0.01,
    log_x = FALSE,
    log_y = FALSE,
    y_min_log = 1e-4,
    y_max = NULL
){

  errorbars <- match.arg(errorbars)

  pred_all <- bind_rows(preds, .id = "data_type")

  if (!is.null(obs)) {
    # shift each dataset's points and bars sideways so they don't entirely
    # overlap. a constant shift in minutes (dodge as a proportion of the x
    # range), so the gap is the same width everywhere on a linear axis
    obs_all <- bind_rows(obs, .id = "data_type") |>
      group_by(data_type) |>
      mutate(
        shift = (cur_group_id() - (length(obs) + 1) / 2) *
          dodge * diff(range(pred_all$tt)),
        tt = pmax(tt + shift, 0)
      ) |>
      ungroup()
  }

  if (is.null(y_max)) {
    y_max <- max(
      pred_all$upper[pred_all$fit == max(pred_all$fit)],
      if (is.null(obs)) 0 else obs_all$rate
    )
  }

  p <- ggplot(pred_all, aes(x = tt, col = data_type, fill = data_type)) +
    geom_ribbon(
      aes(ymin = lower, ymax = upper),
      alpha = 0.3,
      col = NA
    ) +
    geom_line(aes(y = fit))

  if (!is.null(obs) && errorbars != "none") {
    bar_limits <- switch(
      errorbars,
      percentile = aes(ymin = q05, ymax = q95),
      ci90 = aes(ymin = ci90_lower, ymax = ci90_upper)
    )

    p <- p +
      geom_errorbar(
        data = obs_all,
        bar_limits,
        width = 0
      )
  }

  if (!is.null(obs)) {
    p <- p +
      geom_point(
        data = obs_all |>
          filter(!log_y | rate > 0),
        aes(y = rate)
      )
  }

  p <- p +
    scale_colour_manual(
      values = data_type_colours(),
      guide = guide_legend(title = "Data type")
    ) +
    scale_fill_manual(
      values = data_type_colours(),
      guide = "none"
    ) +
    labs(
      x = "Travel time from a research location (minutes)",
      y = expression("Number of occurrence records per 100 km"^2)
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
