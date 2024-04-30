get_travel_time <- function(
  friction_surface,
  points,
  t_filename = "outputs/areaT.rds",
  tgc_filename = "outputs/areaTGC.rds",
  travel_time_filename = "outputs/travel_time.tif",
  overwrite_raster = TRUE,
  #overwrite_t = TRUE,
  split_grain = 1 # split friction_surface into split_grain^2 approximately equal geographic sized rasters
){

  npoints <- nrow(points)


  fri <- sdmtools::split_rast(friction_surface, grain = split_grain)

  tgc <- fri |>
    lapply(
      FUN = raster::raster
    ) |>
    lapply(
      FUN = function(z){
        gdistance::transition(z, function(x) 1/mean(x), 8)
      }
    ) |>
    lapply(
      FUN = geoCorrection
    )


  friction <- raster::raster(friction_surface)

  # if(!file.exists(t_filename) | (file.exists(t_filename) & overwrite_t)){
  #   tsn <- transition(friction, function(x) 1/mean(x), 8) # RAM intensive, can be very slow for large areas
  #   saveRDS(tsn, t_filename)
  # } else {
  #   tsn <- readRDS(t_filename)
  # }

  z <- merge(rast(raster(tgc[[1]])), rast(raster(tgc[[2]])), rast(raster(tgc[[3]])), rast(raster(tgc[[4]])))
  x <- raster(z)

  nr <- as.integer(nrow(x))
  nc <- as.integer(ncol(x))

  tr <- new("TransitionLayer",
            transitionMatrix = as.matrix(x) |> Matrix(data = _, sparse = TRUE),
            nrows = nr,
            ncols = nc,
            extent = extent(x),
            crs = projection(x, asText = FALSE),
            matrixValues = "conductance")


  # tgc <- geoCorrection(tsn)
  # saveRDS(tgc, tgc_filename)

  xy.data.frame <- data.frame()
  xy.data.frame[1:npoints,1] <- points[,1]
  xy.data.frame[1:npoints,2] <- points[,2]
  xy.matrix <- as.matrix(xy.data.frame)

  temp.raster <- accCost(tgc, xy.matrix)

  writeRaster(temp.raster, travel_time_filename, overwrite = overwrite_raster)

  rast(travel_time_filename)

}
