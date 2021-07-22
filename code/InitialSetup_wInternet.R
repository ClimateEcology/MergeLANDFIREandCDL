# steps of grid/merge workflow that require internet connection.
# includes downloading state shapefile to clip national rasters

library(dplyr); library(sf)

bystate <- T
wholecountry <- T
regionName <- 'National'

states <- c('West Virginia', 'Pennsylvania', 'Maryland',
                    'Delaware', 'New Jersey', 'New York', 'New Hampshire', 'Vermont', 'Maine', 'Connecticut',
                    'Massachusetts', 'Rhode Island') # list of states within region


if (bystate == T & wholecountry == F) {
  # download shapefile of US states
  region <- tigris::states() %>% sf::st_as_sf() %>%
    dplyr::filter(NAME %in% states) # filter to only selected states
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), append=F)
  
} else if (bystate == T & wholecountry == T) {
  # download shapefile of US states
  region <- tigris::states() %>% sf::st_as_sf() %>%
    dplyr::filter(!NAME %in% c('Alaska', 'American Samoa', 'Commonwealth of the Northern Mariana Islands', 
                               'Guam', 'Hawaii', 'Puerto Rico', 'United States Virgin Islands'))
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), append=F)
  
} else if (bystate == F) {
  # download shapefile of US states
  region <- tigris::states() %>% sf::st_as_sf() %>%
    dplyr::filter(NAME %in% states) %>% # filter to only selected states
    sf::st_union()  
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '_OnePoly.shp'), append=F)
}
