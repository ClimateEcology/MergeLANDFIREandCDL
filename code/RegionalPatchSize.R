library(landscapemetrics); library(tigris); library(dplyr)

regionName <- 'Northeast'; CDLYear <- 2016
generateCDL <- T


if (generateCDL == T) {
  
  # load shapefile for state/region 
  regionalextent <- sf::st_read(paste0('./data/SpatialData/', regionName , '_OnePoly.shp'))
  
  # re-project regional extent to match shp  
  region_sf <- sf::st_transform(regionalextent, crs = sf::st_crs(cdl))
  
  region_cdl <- raster::raster(cdl_path) %>%
    raster::crop(y=region_sf)
  
  raster::writeRaster(region_cdl, paste0('./data/SpatialData/', regionName, 'CDL.tif'))
}  


land <- raster::raster(paste0('./data/SpatialData/', regionName, 'CDL.tif'))


check <- check_landscape(land, verbose=T)

if (!check$units == 'm' & check$class == 'integer') {
  stop('Check raster file for landscape. Seems like there is a problem')
}

# calculate mean patch size for the entire NE region
mean_patch_size <- lsm_l_area_mn(land)
print(mean_patch_size)