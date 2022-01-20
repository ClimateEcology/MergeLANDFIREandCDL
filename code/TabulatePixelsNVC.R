library(dplyr)

nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')

states <- sf::st_read('./data/SpatialData/National.shp') %>%
  sf::st_transform(crs = sf::st_crs(nvc))

for (state in unique(states$STUSPS)) {
  
  one_state <- dplyr::filter(states, STATE==state) #%>%
    #sf::st_combine()
  
  one_nvc <- raster::crop(nvc, raster::extent(one_state)) %>%
    terra::mask(one_state)

  nvc_freq <- raster::freq(one_nvc, progress=T, merge=T) %>%
    data.frame() %>%
    dplyr::mutate(State = state) %>%
    dplyr::rename(NVC_Class = value, NCells=count)

  logger::log_info(paste0("Finished ", state, "."))
  
  if (state == unique(states$STATE)[1]) {
    all_freq <- nvc_freq
  }  else {
    all_freq <- rbind(all_freq, nvc_freq)
  }
}

write.csv(all_freq, './data/NVC_StatePixelFreq.csv')