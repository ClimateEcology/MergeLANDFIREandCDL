tabulate_pixels_bystate <- function(rastpath, statepath, outpath) {
  
  library(dplyr)
  
  national_raster <- raster::raster(rastpath)
  
  states <- sf::st_read(statepath) %>%
    dplyr::filter(!is.na(STATE)) %>% # take out state polygons that are all NA (sections of Great Lakes, for example)
    dplyr::group_by(STATE) %>%
    summarize(geometry=sf::st_combine(geometry)) %>%
    sf::st_transform(crs = sf::st_crs(national_raster))
  
  
  for (state in unique(states$STUSPS)) {
    
    one_state <- dplyr::filter(states, STUSPS==state)
    
    onestate_raster <- raster::crop(national_raster, raster::extent(one_state)) %>%
      raster::mask(one_state)
  
    freq <- raster::freq(onestate_raster, progress=T, merge=T) %>%
      data.frame() %>%
      dplyr::mutate(State = state) %>%
      dplyr::rename(Class = value, NCells=count)
  
    logger::log_info(paste0("Finished ", state, "."))
    
    if (state == unique(states$STUSPS)[1]) {
      all_freq <- freq
    }  else {
      all_freq <- rbind(all_freq, freq)
    }
    logger::log_info('Finished ', one_county$STATE)
  }
  
  write.csv(all_freq, outpath, row.names = F)
}