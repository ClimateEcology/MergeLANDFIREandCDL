# steps of grid/merge workflow that require internet connection.
# includes downloading state shapefile to clip national rasters

library(dplyr); library(sf)

bystate <- T
wholecountry <- F
regionName <- 'Midwest'

national <- tigris::states() %>% sf::st_as_sf() %>%
  dplyr::filter(!NAME %in% c('Alaska', 'American Samoa', 'Commonwealth of the Northern Mariana Islands', 
                             'Guam', 'Hawaii', 'Puerto Rico', 'United States Virgin Islands'))

if (regionName == 'Northeast') {
  states <- national$NAME[national$REGION == 1]
} else if (regionName == 'Southeast') {
  states <- national$NAME[national$REGION == 2]
} else if (regionName == 'Midwest') {
  states <- national$NAME[national$REGION == 3]
} else if (regionName == 'West') {
  states <- national$NAME[national$REGION == 4]
}


if (bystate == T & wholecountry == F) {
  # download shapefile of US states
  region <- dplyr::filter(national, NAME %in% states) # filter to only selected states
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), append=F)
  
} else if (bystate == T & wholecountry == T) {
  # download shapefile of US states
  region <- national
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), append=F)
  
} else if (bystate == F) {
  # download shapefile of US states
  region <- dplyr::filter(national, NAME %in% states) %>% # filter to only selected states
    sf::st_union()  
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '_OnePoly.shp'), append=F)
}
