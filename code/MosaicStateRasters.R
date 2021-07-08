rm(list=ls())

library(dplyr); library(terra)
CDLYear <- 2016

# save list of directories w/ finished state maps
is_tile_dir <- list.dirs('./data', full.names = T, recursive = F) %>%
  stringr::str_detect(pattern='(..)Tiles')

dirs_tomerge <- list.dirs('./data', full.names = T, recursive = F)[is_tile_dir]

# save list of file paths to state rasters
for (i in 1:length(dirs_tomerge)) {
  temp <- list.files(dirs_tomerge[i], full.names = T)
  oneraster <- temp[grepl(temp, pattern='Final') & 
    grepl(temp, pattern=as.character(get('CDLYear')))] # only process rasters that match the CDL year specified above
  
  if (i == 1) {
    allrasters <- oneraster
  } else {
    allrasters <- c(allrasters, oneraster)
  }
}

# make list of actual raster objects (not file paths)
allstates <- vector("list", length(allrasters))

for (i in 1:length(allrasters)) {
  allstates[[i]] <- terra::rast(allrasters[i])
}

# execute mosaic function
allstates_map <- rlang::exec("mosaic", !!!allstates, fun='mean', filename=paste0('./data/NationalMergedRaster', CDLYear, '.tif'), overwrite=T)