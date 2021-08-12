mosaic_state_rasters <- function(CDLYear, parentdir='./data', 
                                 tilestring='(..)Tiles',
                                 IDstring1=NA,
                                 IDstring2=NA,
                                 IDstring3=NA,
                                 season=NA,
                                 outdir) {
    
  library(dplyr); library(terra)
  
  # save list of directories w/ finished state maps
  dirs <- list.dirs(parentdir, full.names = T, recursive = T)
  
  is_tile_dir <- dirs %>%
    stringr::str_detect(pattern=tilestring)
  
  if (all(is.na(c(IDstring1, IDstring2, IDstring3)))) {
    dirs_tomerge <- dirs[is_tile_dir]
  
  } else if (any(!is.na(c(IDstring1, IDstring2, IDstring3)))) {
    
    if (!is.na(IDstring1)) {
      is_IDstring1 <- dirs %>%
        stringr::str_detect(pattern=IDstring1)
      filterby <- is_tile_dir & is_IDstring1
    }
    if (!is.na(IDstring2)) {
      is_IDstring2 <- dirs %>%
        stringr::str_detect(pattern=IDstring2)
      
      filterby <- filterby & is_IDstring2
    }
    
    if (!is.na(IDstring3)) {
      is_IDstring3 <- dirs %>%
        stringr::str_detect(pattern=IDstring3)
      filterby <- filterby & is_IDstring3
    
    } 
      dirs_tomerge <- dirs[filterby]
      dirs_tomerge <- dirs_tomerge[!grepl(dirs_tomerge, pattern= "ClippedTiles")]
  }
  
  
  # save list of file paths to state rasters
  for (i in 1:length(dirs_tomerge)) {
    temp <- list.files(dirs_tomerge[i], full.names = T)
    
    if (!is.na(season)) {
      
      oneraster <- temp[grepl(temp, pattern='Final') & 
        grepl(temp, pattern=as.character(get('CDLYear'))) & # only process rasters that match the CDL year specified
        grepl(temp, pattern=season)]
      
    } else {
      oneraster <- temp[grepl(temp, pattern='Final') & 
        grepl(temp, pattern=as.character(get('CDLYear')))]
    }
    
    if (i == 1) {
      allrasters <- oneraster
    } else {
      allrasters <- c(allrasters, oneraster)
    }
  }
  
  if (length(allrasters) > 0) {
    ID <- gsub(basename(allrasters[1]), pattern='_FinalRaster.tif', replacement = '')
    # make list of actual raster objects (not file paths),
    allstates <- vector("list", length(allrasters))
    
    for (i in 1:length(allrasters)) {
      allstates[[i]] <- terra::rast(allrasters[i])
    }
    
    logger::log_info(paste0(allrasters, collapse=', '))
    
    
    # execute mosaic function
    allstates_map <- rlang::exec("mosaic", !!!allstates, fun='mean', 
      filename=paste0(outdir, '/National_', ID, '.tif'), overwrite=T)
  } else if (length(allrasters == 0)) {
    warn("There are no rasters that match the IDstring(s) and CDLYear ", CDLYear, ". No mosaic operation performed.")
  }
}