addcounty <- function(x) {
  library(raster); library(dplyr)
  
  # load NVC raster (just to grab projection information)
  nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
  
  # load csv of mismatch points for one tile
  tile_pts <- read.csv(x) %>%
    sf::st_as_sf(coords=c('x', 'y'), crs= crs(nvc), remove=F) # convert to sf object, defining CRS
  
  # load shapefile of county boundaries
  counties <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
    dplyr::select(STATE, COUNTY, FIPS) %>%
    sf::st_transform(crs = sf::st_crs(tile_pts)) # project county polygons to match points
  
  # add county name and FIPS code to points object based on spatial intersection
  pts_wcounty <- tile_pts %>%
    sf::st_join(counties, join=sf::st_intersects) %>%
    sf::st_drop_geometry() # remove spatial data
  
  return(pts_wcounty)
}