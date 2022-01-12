
check_rastersize <- function(dir, cutoff_pct) {
  
  # remove output file if it exists in env
  if (exists('smallfile_years')) {
  rm(smallfile_years, state, years) 
  }
  
  files = list.files(dir, pattern='FinalRasterCompress', full.names=T)
  filesizes <- file.size(files)
  
  for (i in 1:length(filesizes)) {
    isoutlier <- filesizes[i] < max(filesizes)* cutoff_pct
    isTexas <- grepl(basename(files[i]), pattern="TX_East")|grepl(basename(files[i]), pattern="TX_West")
    
    if (isoutlier == T) {
      if (isTexas) {
        smallfile_year <- stringr::str_sub(basename(files[i]), start=12, end=15)
      } else if (!isTexas) {
        smallfile_year <- stringr::str_sub(basename(files[i]), start=7, end=10)
        
      }
      if (exists('smallfile_years')) {
        smallfile_years <- c(smallfile_years, smallfile_year)
      } else {
        smallfile_years <- smallfile_year
      }
    }
  }
  
  # output warning if some output rasters are less than 90% max file size
  if (grepl(basename(files[i]), pattern="TX_East")|grepl(basename(files[i]), pattern="TX_West")) {
    state <- stringr::str_sub(basename(files[i]), start=1, end=7)
  } else {
    state <- stringr::str_sub(basename(files[i]), start=1, end=2)
    
  }
  
  if (exists('smallfile_years')) {
    years <- paste0(smallfile_years, collapse=", ")
    
    warning(paste0(state, " had suspiciously small raster output in ", years, ". Check if mosaic function excluded tiles."))
  } else {
    print(paste0(state, " rasters look fine."))
  }
}