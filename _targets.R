# library(devtools)
# library(usethis)
# .libPaths("~/R/library/")

# install.packages("geotargets", repos = c("https://njtierney.r-universe.dev", "https://cran.r-project.org"))
# remotes::install_github("idem-lab/sdmtools")

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
    "geotargets"
  )#,
  #controller = crew_controller_local(workers = 4)
)


# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
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
  tar_terra_vect(
    africa_mask_v,
    sdmtools::make_africa_mask(
      file_name = "data/spatial/africa_mask.gpkg",
      type = "vector"
    )
  ),
  # tar_terra_vect(
  #   africa_mask_v,
  #   sdmtools::make_africa_mask(
  #     file_name = "data/spatial/nga_mask.gpkg",
  #     type = "vector",
  #     countries = "NGA"
  #   )
  # ),
  tar_target(
    africa_points,
    select_points(
      points = locations,
      poly = africa_mask_v
    )
  ),
  tar_terra_vect(
    africa_points_v,
    point_tbl_to_vect(
      africa_points
    )
  ),
  tar_target(
    friction_file,
    "data/spatial/2020_motorized_friction_surface.geotiff",
    format = "file"
  ),
  tar_terra_rast(
    friction_surface,
    terra::rast(friction_file) |>
      terra::crop(
        y = africa_mask_v,
        mask = TRUE
      )
  ),
  tar_terra_rast(
    travel_time,
    get_travel_time(
      friction_surface = friction_surface,
      points = africa_points,
      travel_time_filename = "outputs/travel_time.tif",
      overwrite_raster = TRUE,
      overwrite_t = TRUE
    )
  )
)
