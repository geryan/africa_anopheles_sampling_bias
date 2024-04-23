# library(devtools)
# library(usethis)

# tar_load_globals()
# tar_load_everything()
# tar_visnetwork()

library(targets)

tar_option_set(
  packages = c(
    "dplyr",
    "readr",
    "sdmtools",
    "terra",
    "gdistance",
    "raster"
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
    read_csv(file = locations_file)
  )
)
