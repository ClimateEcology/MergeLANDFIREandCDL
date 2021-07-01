rm(list=ls())

library(dplyr)
# save list of directories w/ finished state maps
is_tile_dir <- list.dirs('./data', full.names = T, recursive = F) %>%
  stringr::str_detect(pattern='(..)Tiles')

dirs_tomerge <- list.dirs('./data', full.names = T, recursive = F)[is_tile_dir]

# save list of file paths to merged rasters
for (i in 1:length(dirs_tomerge)) {
  temp <- list.files(dirs_tomerge[i], full.names = T)
  oneraster <- temp[grepl(temp, pattern='Final')]
  
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

allstates_map <- terra::mosaic(allstates, fun='mean')
