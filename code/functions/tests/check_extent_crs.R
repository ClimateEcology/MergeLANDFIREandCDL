
check_extent_crs <- function(dir) {
  
  # remove output file if it exists in env
  if (exists('res')) {
    rm(files, onerast, refrast, crs_match, ext_match, res, onerow) 
  }
  
  files <- list.files(dir, pattern='FinalRasterCompress', full.names=T)

  # save state name
  if (grepl(basename(files[i]), pattern="TX_East")|grepl(basename(files[i]), pattern="TX_West")) {
    state <- stringr::str_sub(basename(files[i]), start=1, end=7)
  } else {
    state <- stringr::str_sub(basename(files[i]), start=1, end=2)
  }
  
  for (onefile in files) {
    
  onerast <- terra::rast(onefile)
  
  if (onefile == files[1]) {
    refrast <- onerast
  }
  
  crs_match <- terra::crs(onerast) == terra::crs(refrast)
  ext_match <- terra::ext(onerast) == terra::ext(refrast)
  
  onerow <- tibble::tibble(Raster=onerast, CompareTo=files[1], CRS_match=crs_match, Extent_match=ext_match)
  
  if (onefile == files[1]) {
    res <- onerow
  } else {
    res <- rbind(res, onerow)
  }
  
  # warn if CRS does not match
  if (any(!res$CRS_match)) {
    warning(paste0(state, " CRS does not match reference raster in at least one year."))
  }
  
  if (any(!res$Extent_match)) {
    warning(paste0(state, " extent does not match reference raster in at least one year."))
  
    } else if (all(res$CRS_match) & all(res$Extent_match)) {
    logger::log_info(paste0('Check raster crs & extent: ', state, " rasters look good."))
  }
  
  }
}
  