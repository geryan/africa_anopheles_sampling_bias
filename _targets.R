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

  tar_target(
    occurrences,
    getVecOcc(continent = "Africa")
  ),


  tar_terra_vect(
    occ_pts,
    bind_cols(
      occurrences |>
        as.data.frame(),
      occurrences |>
        st_coordinates()
    ) |>
      as_tibble() |>
      select(-geometry) |>
      vect(
        geom = c("X", "Y"),
        crs = crs(africa_points_v)
      )
  ),

  # vector occurrence and research locations together, labelled by data_type
  tar_terra_vect(
    all_pts,
    combine_point_types(
      occ_pts,
      africa_points_v
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
          filter(data_type == "Vector\noccurrence"),
        colours = "gold",
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
        colours = c("deeppink", "gold"),
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
        colours = c("deeppink", "gold")
      ),
      "outputs/figures/vec_occ_res_tt.png"
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

  tar_target(
    annoying_end_of_list_thing,
    "so I don't need to wonder about adding the comma or not"
  )

)

# plots of points overlaying travel time


