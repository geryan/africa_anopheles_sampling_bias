# negative binomial gam of records per cell against travel time, with cell
# land area as an offset, fitted to cells with travel time <= max_tt. returns
# predicted records per 100 km2 with 95% CI. smooth is either "linear"
# (s(tt)) or "log1p" (s(log1p(tt)))
fit_tt_occ_gam <- function(
    tt_occ_data,
    max_tt = Inf,
    smooth = c("linear", "log1p"),
    n_pred = 200
){

  smooth <- match.arg(smooth)

  dat <- tt_occ_data |>
    filter(tt <= max_tt)

  form <- switch(
    smooth,
    linear = count ~ s(tt) + offset(log(area_km2 / 100)),
    log1p = count ~ s(log1p(tt)) + offset(log(area_km2 / 100))
  )

  fit <- mgcv::bam(
    form,
    family = mgcv::nb(),
    data = dat,
    discrete = TRUE
  )

  pred_dat <- tibble(
    # over the range of the data (no extrapolation to zero), evenly spaced on
    # log1p scale so curve is smooth on either axis scale
    tt = expm1(
      seq(
        log1p(min(dat$tt)),
        log1p(max(dat$tt)),
        length.out = n_pred
      )
    ),
    area_km2 = 100
  )

  pred <- predict(fit, newdata = pred_dat, type = "link", se.fit = TRUE)

  pred_dat |>
    mutate(
      max_tt = max_tt,
      smooth = smooth,
      fit = exp(pred$fit),
      lower = exp(pred$fit - 1.96 * pred$se.fit),
      upper = exp(pred$fit + 1.96 * pred$se.fit)
    )

}
