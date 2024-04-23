# library(devtools)
# library(usethis)

library(targets)
library(geotargets)


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
  )
)


# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.

# Replace the target list below with your own:
list(
  tar_target(
    locations_file,
    "data/tabular/research_locations_20240415.csv",
    format = "file"
  ),
  tar_target(
    locations,
    readr::read_csv(file = locations_file)
  ),
  tar_terra_vect(
    africa_mask_v,
    sdmtools::make_africa_mask(
      file_name = "data/spatial/africa_mask.gpkg",
      type = "vector"
    )
  )
)
