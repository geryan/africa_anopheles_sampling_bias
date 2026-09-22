# crop (rasters) and mask a SpatRaster or SpatVector to a single country
mask_to_country <- function(x, country_shps_v, iso3){

  pol <- country_shps_v[country_shps_v$country == iso3, ]

  if (inherits(x, "SpatRaster")) {
    x <- crop(x, pol)
  }

  mask(x, pol)

}
