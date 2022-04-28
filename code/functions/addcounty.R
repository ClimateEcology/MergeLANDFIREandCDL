addcounty <- function(x, prj, shape) {
  suppressPackageStartupMessages(library("dplyr"))
  suppressPackageStartupMessages(library("raster"))
  
  library(raster); library(dplyr)
  
  # load csv of mismatch points for one tile
  tile_pts <- read.csv(x) %>%
    sf::st_as_sf(coords=c('x', 'y'), crs= prj, remove=F) # convert to sf object, defining CRS
  
  # load shapefile of county boundaries
  counties <- shape %>%
    sf::st_transform(crs = sf::st_crs(tile_pts)) # project county polygons to match points
  
  # add county name and FIPS code to points object based on spatial intersection
  pts_wcounty <- tile_pts %>%
    sf::st_join(counties, join=sf::st_intersects) %>%
    sf::st_drop_geometry() # remove spatial data
  
  return(pts_wcounty)
}