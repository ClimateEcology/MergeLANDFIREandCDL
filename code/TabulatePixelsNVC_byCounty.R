library(dplyr)

nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')

counties <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
  sf::st_transform(crs = sf::st_crs(nvc))

for (i in 1:length(counties$COUNTY)) {
  
  one_county <- counties[i, ] #%>%
    #sf::st_combine()
  
  one_nvc <- raster::crop(nvc, raster::extent(one_county)) %>%
    terra::mask(one_county)

  nvc_freq <- raster::freq(one_nvc, progress=T, merge=T) %>%
    data.frame() %>%
    dplyr::mutate(State = one_county$STATE, County=one_county$COUNTY) %>%
    dplyr::rename(NVC_Class = value, NCells=count)

  if (i == 1) {
    all_freq <- nvc_freq
  }  else {
    all_freq <- rbind(all_freq, nvc_freq)
  }
}

write.csv(all_freq, './data/NVC_CountyPixelFreq.csv')