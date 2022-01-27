tabulate_pixels_bycounty <- function(rastpath, countypath, outpath) {
  
  library(dplyr)
    
  national_raster <- raster::raster(rastpath)
  
  counties <- sf::st_read(countypath) %>%
    sf::st_transform(crs = sf::st_crs(national_raster))
  
  for (i in 1:length(counties$COUNTY)) {
    
    one_county <- counties[i, ] #%>%
      #sf::st_combine()
    
    onecounty_raster <- raster::crop(national_raster, raster::extent(one_county)) %>%
      raster::mask(one_county)
  
    freq <- raster::freq(onecounty_raster, progress=T, merge=T) %>%
      data.frame() %>%
      dplyr::mutate(State = one_county$STATE, County=one_county$COUNTY) %>%
      dplyr::rename(Class = value, NCells=count)
  
    if (i == 1) {
      all_freq <- freq
    }  else {
      all_freq <- rbind(all_freq, freq)
    }
  }
  
  write.csv(all_freq, outpath, row.names = F)

}