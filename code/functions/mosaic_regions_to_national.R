mosaic_regions_to_national <- function(CDLYear, regionaldir='./data', 
                                 IDstring1=NA,
                                 IDstring2=NA,
                                 IDstring3=NA,
                                 season=NA,
                                 outdir) {
    
  library(dplyr); library(terra)
  
  # save list of finished regional
  reg_filepaths <- list.files(regionaldir, full.names = T, recursive = T)
  
  if (any(!is.na(c(IDstring1, IDstring2, IDstring3)))) {
    
    if (!is.na(IDstring1)) {
      is_IDstring1 <- reg_filepaths %>%
        stringr::str_detect(pattern=IDstring1)
      filterby <- is_IDstring1
    }
    if (!is.na(IDstring2)) {
      is_IDstring2 <- reg_filepaths %>%
        stringr::str_detect(pattern=IDstring2)
      
      filterby <- filterby & is_IDstring2
    }
    
    if (!is.na(IDstring3)) {
      is_IDstring3 <- reg_filepaths %>%
        stringr::str_detect(pattern=IDstring3)
      filterby <- filterby & is_IDstring3
    
    } 
      files_tomerge <- reg_filepaths[filterby]
  }
  
  # filter to appropriate CDL year and season
  if (!is.na(season)) {
    
    files_tomerge <- files_tomerge[grepl(files_tomerge, pattern=as.character(get('CDLYear'))) &
                                   grepl(files_tomerge, pattern=season) ] # only process rasters that match the CDL year and season specified
  } else {
    files_tomerge <- files_tomerge[grepl(files_tomerge, pattern=as.character(get('CDLYear')))]
  }
  
  # make list of actual raster objects (not file paths),
  if (length(files_tomerge) > 0) {
    ID <- gsub(basename(files_tomerge[1]), pattern='.tif', replacement = '') %>%
      gsub(pattern='Midwest|Northeast|Southeast|West', replacement='')
    
    allregions <- vector("list", length(files_tomerge))
    
    for (i in 1:length(files_tomerge)) {
      allregions[[i]] <- terra::rast(files_tomerge[i])
    }
    
    # output copy of the raster file paths included
    logger::log_info(paste0(files_tomerge, collapse=', '))
    
    
    # execute mosaic function
    allregions_map <- rlang::exec("mosaic", !!!allregions, fun='mean', 
      filename=paste0(outdir, '/National_', ID, '.tif'), overwrite=T)
  } else if (length(files_tomerge == 0)) {
    warn("There are no rasters that match the IDstring(s) and CDLYear ", CDLYear, ". No mosaic operation performed.")
  }
}