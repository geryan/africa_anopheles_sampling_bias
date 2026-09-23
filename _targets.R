# library(devtools)
# library(usethis)
# .libPaths("~/R/library/")

# install.packages("geotargets", repos = c("https://njtierney.r-universe.dev", "https://cran.r-project.org"))
# install.packages(c("traveltime", "sdmtools"), repos = c("https://idem-lab.r-universe.dev"))

library(targets)
library(geotargets)
#library(crew)


# tar_load_globals()
# tar_load_everything()
# tar_visnetwork()

tar_option_set(
  packages = c(
    "dplyr",
    "readr",
    "sdmtools",
    "terra",
    #"gdistance",
    #"raster",
    "geotargets",
    "traveltime",
    "purrr",
    "sf",
    "malariaAtlas",
    "tidyterra",
    "ggplot2",
    "patchwork",
    "idpalette",
    "readxl"
  )#,
  #controller = crew_controller_local(workers = 4),
  #format = "qs"
)


tar_source()

list(
  # get location data
  #
  # tar_target(
  #   locations_new_file,
  #   "data/tabular/unique_entries 26.sep.2024.xls",
  #   format = "file"
  # ),
  # tar_target(
  #   locations_new,
  #   read_excel(
  #     path = locations_new_file,
  #     sheet = "unique_entries 12.sep.204"
  #   ) |>
  #     select(
  #       x = Longitude,
  #       y = Latitude
  #     ) |>
  #      mutate(
  #        x = as.numeric(x),
  #        y = as.numeric(y)
  #      ) |>
  #     filter(!is.na(x) & !is.na(y)) |>
  #     distinct()
  # ),
  #
  # # original smaller set by Gia
  # tar_target(
  #   locations_ktu_file,
  #   "data/tabular/lake_region_source_counts.csv",
  #   format = "file"
  # ),
  #
  # tar_target(
  #   locations_ktu,
  #   readr::read_csv(file = locations_ktu_file) |>
  #     dplyr::select(longitude, latitude) |>
  #     dplyr::rename(x = longitude, y = latitude)
  # ),
  #
  # # join together
  # # nb this will include all locations outside as well as inside of Africa
  # tar_target(
  #   locations,
  #   dplyr::bind_rows(
  #     locations_new,
  #     locations_ktu
  #   ) |>
  #     dplyr::distinct()
  # ),

  tar_target(
    locfile,
    "data/tabular/tidy/affiliation_simple_coords.csv",
    format = "file"
  ),

  tar_target(
    locations,
    read_csv(locfile) |>
      select(x = longitude, y = latitude)
  ),

  tar_target(
    tt_countries_all,
    global_regions |>
      dplyr::filter(continent == "Africa") |>
      pull(iso3)
  ),
  tar_target(
    tt_countries,
    #tt_countries_all[c(3, 23, 53)]
    tt_countries_all
  ),
  tar_terra_vect(
    africa_mask_v,
    sdmtools::make_africa_mask(
      filename = "data/spatial/africa_mask.gpkg",
      #filename = "data/spatial/btg_mask.gpkg",
      countries = tt_countries,
      type = "vector"
    )
  ),

  # select to locations just within Africa
  tar_target(
    africa_points,
    select_points(
      points = locations,
      pol = africa_mask_v
    )
  ),
  tar_terra_vect(
    africa_points_v,
    point_tbl_to_vect(
      africa_points
    )
  ),

  ## TT whole continent
  # this version calculates travel time from the nearest research location
  tar_target(
    surface_extent,
    traveltime::ext_from_terra(africa_mask_v)
  ),
  tar_terra_rast(
    friction_surface,
    traveltime::get_friction_surface(
      surface = "motor2020",
      filename = "data/spatial/friction_surface.tif",
      overwrite = TRUE,
      extent = surface_extent
    ) |>
      terra::mask(africa_mask_v)
  ),
  tar_terra_rast(
    travel_time_africa,
    traveltime::calculate_travel_time(
      friction_surface = friction_surface,
      points = africa_points,
      filename = "outputs/travel_time_africa.tif",
      overwrite = TRUE
    )
  ),
  # tar_target(
  #   trave_time_africa_plot,
  #   contour(
  #     travel_time_africa,
  #     filled = TRUE,
  #     nlevels = 14,
  #     col = idem(16)
  #   )
  # ),

  ## TT by country
  # this version calculates from first, the nearest research location
  # within the country, and if none, then the absolute nearest research location
  # the implication of this is that average distance should increase in this
  # version as sites may be closer to a location over a border than within
  tar_target(
    country_shps_filename,
    "data/spatial/country_shps.gpkg"
  ),
  tar_target(
    country_points_list,
    get_points_by_country(
      points = africa_points,
      countries = tt_countries,
      shp_filename = country_shps_filename
    )
  ),
  tar_target(
    points_per_country,
    tibble(
      country = tt_countries,
      npoints = sapply(
        X = country_points_list,
        FUN = nrow
      )
    )
  ),
  tar_terra_vect(
    country_shps_v,
    read_country_shps(
      country_shps_filename,
      points_per_country
    )
  ),
  tar_target(
    country_points_plot,
    make_country_points_plot(country_shps_v)
  ),
  tar_terra_rast(
    travel_time_country,
    travel_time_by_country(
      friction_surface,
      country_shps_v,
      points_per_country,
      travel_time_africa,
      country_points_list
    )
  ),
  tar_terra_rast(
    tt_country,
    merge(
      travel_time_country, travel_time_africa,
      filename = "outputs/tt_by_country.tif",
      overwrite = TRUE
    )
  ),

  ########### some plots

  # occurrence_old: MAP vector occurrence records
  tar_target(
    occurrences_old,
    getVecOcc(continent = "Africa")
  ),


  tar_terra_vect(
    occ_pts_old,
    bind_cols(
      occurrences_old |>
        as.data.frame(),
      occurrences_old |>
        st_coordinates()
    ) |>
      as_tibble() |>
      select(-geometry) |>
      vect(
        geom = c("X", "Y"),
        crs = crs(africa_points_v)
      )
  ),

  # occurrence_new: vector atlas point locations
  tar_target(
    occurrence_new_file,
    "data/tabular/va_point_locations.csv",
    format = "file"
  ),
  tar_target(
    occurrence_new,
    read_occurrence_new(occurrence_new_file)
  ),
  tar_terra_vect(
    occ_pts_new,
    occurrence_tbl_to_vect(
      occurrence_new,
      crs = crs(africa_points_v)
    )
  ),

  # vector occurrence and research locations together, labelled by data_type
  tar_terra_vect(
    all_pts,
    combine_point_types(
      occ_pts_old,
      africa_points_v
    )
  ),
  # as all_pts, plus the occurrence_new points
  tar_terra_vect(
    all_pts_both,
    combine_point_types(
      occ_pts_old,
      africa_points_v,
      occ_pts_new
    )
  ),

  # flat raster mask for Africa
  tar_terra_rast(
    africa_flat_mask,
    make_flat_mask(tt_country)
  ),

  # figures: each target writes a png and returns its path

  ## tt across continent
  tar_target(
    fig_tt,
    save_plot(
      plot_raster_map(travel_time_africa),
      "outputs/figures/tt.png",
      bg = "transparent"
    ),
    format = "file"
  ),

  ## tt by country
  tar_target(
    fig_tt_country,
    save_plot(
      plot_raster_map(tt_country),
      "outputs/figures/tt_country.png",
      bg = "transparent"
    ),
    format = "file"
  ),
  tar_target(
    fig_tt_country_180,
    save_plot(
      plot_tt_capped(
        tt_country,
        africa_mask_v,
        max_tt = 180,
        # same colour scale as fig_tt_country
        limits = minmax(tt_country)[, 1]
      ),
      "outputs/figures/tt_country_180.png",
      bg = "transparent"
    ),
    format = "file"
  ),
  # tt_country without (left) and with (right) the 180 minute mask
  tar_target(
    fig_tt_country_180_panel,
    save_plot(
      plot_raster_map(tt_country) |
        plot_tt_capped(
          tt_country,
          africa_mask_v,
          max_tt = 180,
          limits = minmax(tt_country)[, 1]
        ),
      "outputs/figures/tt_country_180_panel.png",
      width = 3200
    ),
    format = "file"
  ),
  tar_target(
    fig_tt_country_sqrt,
    save_plot(
      plot_raster_map(sqrt(tt_country)),
      "outputs/figures/tt_country_sqrt.png",
      bg = "transparent"
    ),
    format = "file"
  ),

  ## tt plus research locations
  tar_target(
    fig_tt_country_pts,
    save_plot(
      plot_raster_map(
        sqrt(tt_country),
        points = africa_points_v
      ),
      "outputs/figures/tt_country_pts.png",
      bg = "transparent"
    ),
    format = "file"
  ),
  tar_target(
    fig_tt_africa_pts,
    save_plot(
      plot_raster_map(
        sqrt(travel_time_africa),
        points = africa_points_v
      ),
      "outputs/figures/tt_africa_pts.png",
      bg = "transparent"
    ),
    format = "file"
  ),

  ## vector occurrence and research locations
  tar_target(
    fig_vec_occ,
    save_plot(
      plot_data_type_map(
        africa_flat_mask,
        all_pts |>
          filter(data_type == "Old records"),
        colours = data_type_colours(),
        fill_end = 0.7
      ),
      "outputs/figures/vec_occ.png"
    ),
    format = "file"
  ),
  tar_target(
    fig_vec_occ_res,
    save_plot(
      plot_data_type_map(
        africa_flat_mask,
        all_pts,
        colours = data_type_colours(),
        fill_end = 0.7
      ),
      "outputs/figures/vec_occ_res.png"
    ),
    format = "file"
  ),
  tar_target(
    fig_vec_occ_res_tt,
    save_plot(
      plot_data_type_map(
        sqrt(tt_country),
        all_pts,
        colours = data_type_colours()
      ),
      "outputs/figures/vec_occ_res_tt.png"
    ),
    format = "file"
  ),

  ## as above, with occurrence_old and occurrence_new, smaller points and
  ## untransformed travel time
  tar_target(
    occ_point_size_both,
    1
  ),
  tar_target(
    fig_vec_occ_both,
    save_plot(
      plot_data_type_map(
        africa_flat_mask,
        all_pts_both |>
          filter(data_type != "Research\nfacility"),
        colours = data_type_colours(),
        fill_end = 0.7,
        point_size = occ_point_size_both
      ),
      "outputs/figures/vec_occ_both.png"
    ),
    format = "file"
  ),
  tar_target(
    fig_vec_occ_res_both,
    save_plot(
      plot_data_type_map(
        africa_flat_mask,
        all_pts_both,
        colours = data_type_colours(),
        fill_end = 0.7,
        point_size = occ_point_size_both
      ),
      "outputs/figures/vec_occ_res_both.png"
    ),
    format = "file"
  ),
  tar_target(
    fig_vec_occ_res_tt_both,
    save_plot(
      plot_data_type_map(
        tt_country,
        all_pts_both,
        colours = data_type_colours(),
        point_size = occ_point_size_both
      ),
      "outputs/figures/vec_occ_res_tt_both.png"
    ),
    format = "file"
  ),

  ## single-country figures, one branch per country
  tar_target(
    focal_countries,
    c("COD", "NGA", "TZA")
  ),
  tar_target(
    fig_country_tt,
    save_plot(
      plot_country_tt(
        focal_countries,
        tt_country,
        country_shps_v
      ),
      sprintf("outputs/figures/tt_%s.png", focal_countries)
    ),
    pattern = map(focal_countries),
    format = "file"
  ),
  tar_target(
    fig_country_tt_pts,
    save_plot(
      plot_country_tt_pts(
        focal_countries,
        tt_country,
        country_shps_v,
        all_pts
      ),
      sprintf("outputs/figures/tt_pts_%s.png", focal_countries)
    ),
    pattern = map(focal_countries),
    format = "file"
  ),
  tar_target(
    fig_country_tt_panel,
    save_plot(
      plot_country_tt_panel(
        focal_countries,
        tt_country,
        country_shps_v,
        all_pts
      ),
      sprintf("outputs/figures/tt_panel_%s.png", focal_countries),
      width = 3200
    ),
    pattern = map(focal_countries),
    format = "file"
  ),

  ## as above, with occurrence_old and occurrence_new, smaller points and
  ## untransformed travel time
  tar_target(
    fig_country_tt_pts_both,
    save_plot(
      plot_country_tt_pts(
        focal_countries,
        tt_country,
        country_shps_v,
        all_pts_both,
        point_size = occ_point_size_both
      ),
      sprintf("outputs/figures/tt_pts_both_%s.png", focal_countries)
    ),
    pattern = map(focal_countries),
    format = "file"
  ),
  tar_target(
    fig_country_tt_panel_both,
    save_plot(
      plot_country_tt_panel(
        focal_countries,
        tt_country,
        country_shps_v,
        all_pts_both,
        point_size = occ_point_size_both
      ),
      sprintf("outputs/figures/tt_panel_both_%s.png", focal_countries),
      width = 3200
    ),
    pattern = map(focal_countries),
    format = "file"
  ),

  ## the same figures for a group of countries plotted together
  tar_target(
    focal_country_group,
    c("KEN", "UGA", "TZA")
  ),
  tar_target(
    focal_country_group_label,
    paste(focal_country_group, collapse = "_")
  ),
  tar_target(
    fig_country_group_tt,
    save_plot(
      plot_country_tt(
        focal_country_group,
        tt_country,
        country_shps_v
      ),
      sprintf("outputs/figures/tt_%s.png", focal_country_group_label)
    ),
    format = "file"
  ),
  tar_target(
    fig_country_group_tt_pts,
    save_plot(
      plot_country_tt_pts(
        focal_country_group,
        sqrt(tt_country),
        country_shps_v,
        all_pts
      ),
      sprintf("outputs/figures/tt_pts_%s.png", focal_country_group_label)
    ),
    format = "file"
  ),
  tar_target(
    fig_country_group_tt_panel,
    save_plot(
      plot_country_tt_panel(
        focal_country_group,
        sqrt(tt_country),
        country_shps_v,
        all_pts
      ),
      sprintf("outputs/figures/tt_panel_%s.png", focal_country_group_label),
      width = 3200
    ),
    format = "file"
  ),
  # with occurrence_old and occurrence_new, smaller points, raw travel time
  tar_target(
    fig_country_group_tt_pts_both,
    save_plot(
      plot_country_tt_pts(
        focal_country_group,
        tt_country,
        country_shps_v,
        all_pts_both,
        point_size = occ_point_size_both
      ),
      sprintf("outputs/figures/tt_pts_both_%s.png", focal_country_group_label)
    ),
    format = "file"
  ),
  tar_target(
    fig_country_group_tt_panel_both,
    save_plot(
      plot_country_tt_panel(
        focal_country_group,
        tt_country,
        country_shps_v,
        all_pts_both,
        point_size = occ_point_size_both
      ),
      sprintf("outputs/figures/tt_panel_both_%s.png", focal_country_group_label),
      width = 3200
    ),
    format = "file"
  ),

  ## occurrence records per cell against travel time
  tar_target(
    tt_occ_data_old,
    make_tt_occ_data(
      tt_country,
      occ_pts_old,
      agg_fact = 10
    )
  ),
  tar_target(
    tt_occ_data_new,
    make_tt_occ_data(
      tt_country,
      occ_pts_new,
      agg_fact = 10
    )
  ),
  # model variants, one gam per row: maximum travel time (minutes) of cells
  # to fit and plot to, and whether to smooth on raw or log1p travel time
  tar_target(
    tt_occ_models,
    expand.grid(
      max_tt = 180,
      smooth = "linear",
      stringsAsFactors = FALSE
    )
  ),
  # plot each model with these y axes (FALSE linear, TRUE log)
  tar_target(
    tt_occ_log_y,
    FALSE
  ),
  # overlay observed mean records per cell by travel time bin
  tar_target(
    tt_occ_show_obs,
    TRUE
  ),
  # plot each model with each type of errorbar on the observed rates: none,
  # 5th-95th percentiles of per-cell rates, or 90% CI of the rate
  tar_target(
    tt_occ_errorbars,
    c("none", "percentile", "ci90")
  ),
  # y axis upper limit (records per 100 km2) for all versions, anything above
  # is clipped. NULL to fit the axis to the curve and observed rates
  tar_target(
    tt_occ_y_max,
    30
  ),
  tar_target(
    tt_occ_pred_old,
    fit_tt_occ_gam(
      tt_occ_data_old,
      max_tt = tt_occ_models$max_tt,
      smooth = tt_occ_models$smooth
    ),
    pattern = map(tt_occ_models)
  ),
  tar_target(
    tt_occ_pred_new,
    fit_tt_occ_gam(
      tt_occ_data_new,
      max_tt = tt_occ_models$max_tt,
      smooth = tt_occ_models$smooth
    ),
    pattern = map(tt_occ_models)
  ),
  tar_target(
    fig_tt_occ_gam,
    save_plot(
      plot_tt_occ_gam(
        tt_occ_pred_old,
        tt_occ_obs = if (tt_occ_show_obs) {
          bin_tt_occ(tt_occ_data_old, tt_occ_models$max_tt)
        } else {
          NULL
        },
        errorbars = tt_occ_errorbars,
        log_x = tt_occ_models$max_tt > 1000,
        log_y = tt_occ_log_y,
        y_max = tt_occ_y_max
      ),
      sprintf(
        "outputs/figures/tt_occ_gam_%s_%s_%s%s.png",
        ifelse(is.finite(tt_occ_models$max_tt), tt_occ_models$max_tt, "full"),
        tt_occ_models$smooth,
        ifelse(tt_occ_log_y, "logy", "liny"),
        ifelse(tt_occ_errorbars == "none", "", paste0("_", tt_occ_errorbars))
      ),
      width = 2400
    ),
    pattern = cross(
      map(tt_occ_pred_old, tt_occ_models),
      tt_occ_log_y,
      tt_occ_errorbars
    ),
    format = "file"
  ),

  # as fig_tt_occ_gam, with a curve per dataset
  tar_target(
    fig_tt_occ_gam_both,
    save_plot(
      plot_tt_occ_gam_both(
        preds = list(
          "Old records" = tt_occ_pred_old,
          "New records" = tt_occ_pred_new
        ),
        obs = if (tt_occ_show_obs) {
          list(
            "Old records" = bin_tt_occ(
              tt_occ_data_old,
              tt_occ_models$max_tt
            ),
            "New records" = bin_tt_occ(
              tt_occ_data_new,
              tt_occ_models$max_tt
            )
          )
        } else {
          NULL
        },
        errorbars = tt_occ_errorbars,
        log_x = tt_occ_models$max_tt > 1000,
        log_y = tt_occ_log_y,
        y_max = tt_occ_y_max
      ),
      sprintf(
        "outputs/figures/tt_occ_gam_both_%s_%s_%s%s.png",
        ifelse(is.finite(tt_occ_models$max_tt), tt_occ_models$max_tt, "full"),
        tt_occ_models$smooth,
        ifelse(tt_occ_log_y, "logy", "liny"),
        ifelse(tt_occ_errorbars == "none", "", paste0("_", tt_occ_errorbars))
      ),
      width = 2400
    ),
    pattern = cross(
      map(tt_occ_pred_old, tt_occ_pred_new, tt_occ_models),
      tt_occ_log_y,
      tt_occ_errorbars
    ),
    format = "file"
  ),

  tar_target(
    annoying_end_of_list_thing,
    "so I don't need to wonder about adding the comma or not"
  )

)

# plots of points overlaying travel time


