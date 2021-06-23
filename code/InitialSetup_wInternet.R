# steps of grid/merge workflow that require internet connection.

# necessary packages are part of 'geospatial_extend' container, adding to rocker project geospatial image
# container Dockerfile is in 'ContainerLib' repo
library(dplyr); library(sf)

# regionalextent <- c('Maryland')

states <- c('West Virginia', 'Pennsylvania', 'Maryland',
                    'Delaware', 'New Jersey', 'New York', 'New Hampshire', 'Vermont', 'Maine', 'Connecticut',
                    'Massachusetts', 'Rhode Island') # list of states within region OR an sf shapefile
regionName <- 'NorthEast'

# download shapefile of US states
region <- tigris::states() %>% sf::st_as_sf() %>%
  dplyr::filter(NAME %in% states)

sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), append=F)
