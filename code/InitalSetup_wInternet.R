# steps of grid/merge workflow that require internet connection.

# necessary packages are part of 'geospatial_extend' container, adding to rocker project geospatial image
# container Dockerfile is in 'ContainerLib' repo
library(dplyr)

regionalextent <- c('Delaware')

# regionalextent <- c('West Virginia', 'Pennsylvania', 'Maryland',
#                     'Delaware', 'New Jersey', 'New York', 'New Hampshire', 'Vermont', 'Maine', 'Connecticut',
#                     'Massachusetts', 'Rhode Island') # list of states within region OR an sf shapefile

# download shapefile of US states
region <- tigris::states() %>% dplyr::filter(NAME %in% regionalextent)

if (length(regionalextent) > 1) {
  region <- sf::st_combine(region)
}
class(region)

sf::st_write(region, './data/SpatialData/DE.shp', append=F)
