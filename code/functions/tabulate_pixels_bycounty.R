tabulate_pixels_bycounty <- function(rastpath, countypath, outpath) {
  
  library(dplyr)
    
  national_raster <- terra::rast(rastpath)
  
  counties <- sf::st_read(countypath) %>%
    dplyr::filter(!is.na(COUNTY)) %>% # take out state polygons that are all NA (sections of Great Lakes, for example)
    dplyr::group_by(STATE, COUNTY) %>%
    summarize(geometry=sf::st_combine(geometry)) %>%
    sf::st_transform(crs = sf::st_crs(national_raster))
  
  for (i in 1:length(counties$COUNTY)) {
    
    one_county <- counties[i, ] %>%
      terra::vect()
    
    onecounty_raster <- terra::crop(national_raster, terra::ext(one_county)) %>%
      terra::mask(one_county)
  
    freq <- terra::freq(onecounty_raster) %>%
      data.frame() %>%
      dplyr::mutate(State = one_county$STATE, County=one_county$COUNTY) %>%
      dplyr::rename(Class = value, NCells=count)
  
    if (i == 1) {
      all_freq <- freq
    }  else {
      all_freq <- rbind(all_freq, freq)
    }
    logger::log_info('Finished ', one_county$COUNTY, ', ', one_county$STATE)
  }
  
  logger::log_info("All counties finished!")
  write.csv(all_freq, outpath, row.names = F)
}