
check_extent_crs <- function(dir) {
  
  # remove output file if it exists in env
  if (exists('res')) {
    rm(files, onerast, refrast, crs_match, ext_match, res, onerow) 
  }
  
  files <- list.files(dir, pattern='FinalRasterCompress', full.names=T)

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
  
  if (any(res$CRS_match)) {
    
  }
  