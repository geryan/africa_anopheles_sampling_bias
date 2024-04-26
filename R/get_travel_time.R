get_travel_time <- function(
  friction_surface,
  points,
  t_filename = "outputs/areaT.rds",
  tgc_filename = "outputs/areaTGC.rds",
  travel_time_filename = "outputs/travel_time.tif",
  overwrite = TRUE
){

  npoints <- nrow(points)

  friction <- raster::raster(friction_surface)

  tsn <- transition(friction, function(x) 1/mean(x), 8) # RAM intensive, can be very slow for large areas
  saveRDS(tsn, t_filename)
  tgc <- geoCorrection(tsn)
  saveRDS(tgc, tgc_filename)

  xy.data.frame <- data.frame()
  xy.data.frame[1:npoints,1] <- points[,1]
  xy.data.frame[1:npoints,2] <- points[,2]
  xy.matrix <- as.matrix(xy.data.frame)

  temp.raster <- accCost(tgc, xy.matrix)

  writeRaster(temp.raster, travel_time_filename, overwrite = overwrite)

  rast(travel_time_filename)

}
