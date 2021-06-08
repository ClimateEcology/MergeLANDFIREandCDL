# steps of grid/merge workflow that require internet connection.

library(dplyr)
#try adding from Github
devtools::install_github("land-4-bees/beecoSp")


regionalextent <- c('West Virginia', 'Pennsylvania', 'Maryland',
                    'Delaware', 'New Jersey', 'New York', 'New Hampshire', 'Vermont', 'Maine', 'Connecticut',
                    'Massachusetts', 'Rhode Island') # list of states within region OR an sf shapefile

# download shapefile of US states
region <- tigris::states() %>% dplyr::filter(NAME %in% regionalextent)

sf::st_write(region, './data/SpatialData/NE_region.shp')
