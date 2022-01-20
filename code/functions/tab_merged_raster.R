
tab_merged_raster <- function(state_path) {
  if (grepl(state_path, pattern='TX_East')|grepl(state_path, pattern='TX_West')) {
    statename <- stringr::str_sub(state_path, start=-22, end=-16)
  } else {
    statename <- stringr::str_sub(state_path, start=-17, end=-16)
  }
  
  year <- stringr::str_sub(state_path, start=-11, end=-8)
  
  one_raster <- terra::rast(state_path)
  
  raster_freq <- terra::freq(one_raster) %>%
    data.frame() %>%
    dplyr::mutate(State = statename,
                  Year = year,
                  layer = basename(state_path)) %>%
    dplyr::rename(RasterClass = value, NCells=count)
  
  logger::log_info(paste0("Finished ", statename, "."))
  return(raster_freq)
}