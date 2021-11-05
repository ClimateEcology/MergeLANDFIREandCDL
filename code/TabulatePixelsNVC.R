library(dplyr)

nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')

states <- sf::st_read('./data/SpatialData/us_states_better_coasts.shp') %>%
  sf::st_transform(crs = sf::st_crs(nvc))

for (state in unique(states$STATE)[1:4]) {
  
  one_state <- dplyr::filter(states, STATE==state) #%>%
    #sf::st_combine()
  
  one_nvc <- raster::crop(nvc, raster::extent(one_state))

  nvc_freq <- raster::freq(one_nvc, progress=T, merge=T) %>%
    data.frame() %>%
    dplyr::mutate(State = state) %>%
    dplyr::rename(NVC_Class = value, NCells=count)

  if (state == unique(states$STATE)[1]) {
    all_freq <- nvc_freq
  }  else {
    all_freq <- rbind(all_freq, nvc_freq)
  }
}

write.csv(all_freq, './data/NVC_StatePixelFreq.csv')