# steps of grid/merge workflow that require internet connection.
# includes downloading state shapefile to clip national rasters

library(dplyr); library(sf)

bystate <- T
states <- c('West Virginia', 'Pennsylvania', 'Maryland',
                    'Delaware', 'New Jersey', 'New York', 'New Hampshire', 'Vermont', 'Maine', 'Connecticut',
                    'Massachusetts', 'Rhode Island') # list of states within region
regionName <- 'Northeast'

if (bystate == T) {
  # download shapefile of US states
  region <- tigris::states() %>% sf::st_as_sf() %>%
    dplyr::filter(NAME %in% states) # filter to only selected states
  
  # DO I NEED THIS PART???
  
  # # identify closest state to small states (RI causes code to crash for some reason...)
  # state_points <- sf::st_centroid(region)
  # distance <- sf::st_distance(state_points) %>%
  #   as.data.frame() %>%
  #   dplyr::mutate_at(vars(1:nrow(state_points)), as.numeric)
  # 
  # distance[distance == 0] <- NA
  # 
  # states_to_merge <- which(state_points$ALAND < 20000000000)
  # 
  # merge_pair <- c(states_to_merge[1], which(distance[,states_to_merge[1]] == min(distance[,states_to_merge[1]], na.rm=T)))
  # 
  # melting_pot <- dplyr::slice(region, merge_pair) %>%
  #   sf::st_union()
  # 
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), append=F)
} else if (bystate == F) {
  # download shapefile of US states
  region <- tigris::states() %>% sf::st_as_sf() %>%
    dplyr::filter(NAME %in% states) %>% # filter to only selected states
    sf::st_union()  
  
  sf::st_write(region, paste0('./data/SpatialData/', regionName, '_OnePoly.shp'), append=F)
}
