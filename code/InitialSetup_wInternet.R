# steps of grid/merge workflow that require internet connection.
# includes downloading state shapefile to clip national rasters

library(dplyr); library(sf)

bystate <- T
wholecountry <- F

national <- tigris::states() %>% sf::st_as_sf() %>%
  dplyr::filter(!NAME %in% c('Alaska', 'American Samoa', 'Commonwealth of the Northern Mariana Islands', 
                             'Guam', 'Hawaii', 'Puerto Rico', 'United States Virgin Islands'))

# download and write national county-level dataset
national2 <- tigris::states() %>% sf::st_as_sf() 

national_tojoin <- dplyr::select(national2, STATEFP, NAME) %>% 
  dplyr::mutate(STATEFP = formatC(as.integer(STATEFP), width = 2, format = "d", flag = "0"),
                NAME.state=NAME) %>%
  dplyr::select(-NAME) %>%
  sf::st_drop_geometry()

national_counties <- tigris::counties() %>% sf::st_as_sf() %>%
  dplyr::left_join(national_tojoin) %>%
  dplyr::filter(!NAME.state %in% c('Alaska', 'American Samoa', 'Commonwealth of the Northern Mariana Islands', 
                                   'Guam', 'Hawaii', 'Puerto Rico', 'United States Virgin Islands'))

sf::st_write(national_counties, paste0('./data/SpatialData/National_byCounty.shp'), delete_dsn=T, append=F)

# split Texas in half. Code crashes trying to write so many tiles.
texas_counties <- tigris::counties(state='TX')

# calculate county centroids and use these to filter counties into east/west split
county_centroids <- sf::st_centroid(texas_counties) 
county_centroids$lat <- sf::st_coordinates(county_centroids)[,2]
county_centroids$long <- sf::st_coordinates(county_centroids)[,1]

west_counties <- dplyr::filter(county_centroids, long <= -99)
east_counties <- dplyr::filter(county_centroids, long > -99)

west <- dplyr::filter(texas_counties, GEOID %in% west_counties$GEOID) %>%
  sf::st_union() %>%
  sf::st_sf() %>%
  dplyr::mutate(REGION = 3, DIVISION=7, STATEFP=48, GEOID=48, STUSPS='TX_West', NAME='Texas, west')

east <- dplyr::filter(texas_counties, GEOID %in% east_counties$GEOID) %>%
  sf::st_union() %>%
  sf::st_sf() %>%
  dplyr::mutate(REGION = 3, DIVISION=7, STATEFP=48, GEOID=48, STUSPS='TX_East', NAME='Texas, east')

# Add East and West Texas to national map in place of whole Texas
texas <- dplyr::filter(national, STUSPS == 'TX')

texas <- rbind(texas %>% mutate(STUSPS='TX_West', NAME='Texas, west', geometry = west$geometry),
               texas %>% mutate(STUSPS='TX_East', NAME='Texas, east', geometry = east$geometry))

national <- dplyr::filter(national, STUSPS != 'TX') %>% rbind(texas)


for (regionName in c('Northeast', 'Southeast', 'Midwest', 'West')) {
  if (regionName == 'Northeast') {
    states <- national$NAME[national$REGION == 1]
  } else if (regionName == 'Midwest') {
    states <- national$NAME[national$REGION == 2]
  } else if (regionName == 'Southeast') {
    states <- national$NAME[national$REGION == 3]
  } else if (regionName == 'West') {
    states <- national$NAME[national$REGION == 4]
  }
  
  
  if (bystate == T & wholecountry == F) {
    # download shapefile of US states
    region <- dplyr::filter(national, NAME %in% states) # filter to only selected states
    
    sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), delete_dsn=T, append=F)
    sf::st_write(national, paste0('./data/SpatialData/National.shp'), delete_dsn=T, append=F)
    
  } else if (bystate == T & wholecountry == T) {
    # download shapefile of US states
    region <- national
    sf::st_write(region, paste0('./data/SpatialData/', regionName, '.shp'), delete_dsn=T, append=F)
    
  } else if (bystate == F) {
    # download shapefile of US states
    region <- dplyr::filter(national, NAME %in% states) %>% # filter to only selected states
      sf::st_union()  
    
    sf::st_write(region, paste0('./data/SpatialData/', regionName, '_OnePoly.shp'), delete_dsn=T, append=F)
  }
}