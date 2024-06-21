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
    "gdistance",
    "raster",
    "geotargets",
    "traveltime",
    "purrr",
    "sf",
    "malariaAtlas",
    "tidyterra",
    "idpalette"
  )#,
  #controller = crew_controller_local(workers = 4),
  #format = "qs"
)


tar_source()

list(
  tar_target(
    locations_new_file,
    "data/tabular/research_locations_20240415.csv",
    format = "file"
  ),
  tar_target(
    locations_new,
    readr::read_csv(file = locations_new_file)
  ),
  tar_target(
    locations_ktu_file,
    "data/tabular/lake_region_source_counts.csv",
    format = "file"
  ),
  tar_target(
    locations_ktu,
    readr::read_csv(file = locations_ktu_file) |>
      dplyr::select(longitude, latitude) |>
      dplyr::rename(x = longitude, y = latitude)
  ),
  tar_target(
    locations,
    dplyr::bind_rows(
      locations_new,
      locations_ktu
    ) |>
      dplyr::distinct()
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
  tar_target(
    trave_time_africa_plot,
    contour(
      travel_time_africa,
      filled = TRUE,
      nlevels = 14,
      col = idem(16)
    )
  ),

  ## TT by country
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
  )
)

# plots of points overlaying travel time


