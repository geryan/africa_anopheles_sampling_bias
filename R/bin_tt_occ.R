# observed occurrence records per 100 km2 in travel time bins, for cells with
# travel time <= max_tt. bins are evenly spaced on log1p scale. rate is total
# records over total land area in the bin (so small coastal cells get little
# weight), with a 90% CI from the ratio estimator standard error (normal
# approximation, floored at zero). q05 and q95 are the 5th and 95th
# percentiles of per-cell rates
bin_tt_occ <- function(tt_occ_data, max_tt = Inf, n_bins = 25){

  dat <- tt_occ_data |>
    filter(tt <= max_tt) |>
    mutate(
      area_100 = area_km2 / 100,
      cell_rate = count / area_100
    )

  breaks <- expm1(
    seq(
      0,
      log1p(max(dat$tt)),
      length.out = n_bins + 1
    )
  )
  # expm1(log1p(x)) can fall just short of x, dropping the largest cell
  breaks[length(breaks)] <- Inf

  dat |>
    mutate(
      bin = cut(tt, breaks, include.lowest = TRUE)
    ) |>
    group_by(bin) |>
    summarise(
      tt = mean(tt),
      rate = sum(count) / sum(area_100),
      se = sqrt(
        sum((count - rate * area_100)^2) / (n() * (n() - 1))
      ) / mean(area_100),
      q05 = quantile(cell_rate, 0.05),
      q95 = quantile(cell_rate, 0.95),
      n_cells = n()
    ) |>
    mutate(
      ci90_lower = pmax(rate - qnorm(0.95) * se, 0),
      ci90_upper = rate + qnorm(0.95) * se
    )

}
