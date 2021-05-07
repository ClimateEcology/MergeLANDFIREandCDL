rm(list=ls())

library(dplyr)
# specify input parameters
data_dir <- './data' #directory where tabular and spatial data are stored
window_size <- 7 # diameter of neighborhood analysis window (part 2, only invoked for mis-match between LANDFIRE and CDL)
CDLYear <- '2016'
# regionalextent <- c('West Virginia', 'Pennsylvania', 'Maryland',
#                     'Delaware', 'New Jersey', 'New York', 'New Hampshire', 'Vermont', 'Maine', 'Connecticut', 
#                     'Massachusetts', 'Rhode Island') # list of states within region OR an sf shapefile
regionalextent <- c('Pennsylvania')
skipNAtiles <- T
writetiles <- T
buffercells <- c(3,3)
div <- c(10,10)
NAvalues <- c(0,-9999)

##### derived parameters 
#tile_dir = paste0(data_dir, "/NETiles")
tile_dir = paste0(data_dir, "/PATiles")
evt_path <- paste0(data_dir, '/SpatialData/LANDFIRE/US_105evt/grid1/us_105evt')
nvc_path <- paste0(data_dir, '/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
cdl_path <- paste0(data_dir, '/SpatialData/CDL/', CDLYear, '_30m_cdls.img')

rpath <- c(cdl_path, nvc_path)


source('./code/functions/grid_rasters.R')

tictoc::tic()
# run function to grid NE into tiles (using parameters above)
tiles <- grid_rasters(rpath=rpath, CDLYear=CDLYear,
            regionalextent=regionalextent, tile_dir=tile_dir, 
            div=div, buffercells=buffercells,
            window_size=window_size, skipNAtiles=skipNAtiles, 
            NAvalues=NAvalues, writetiles=writetiles)
tictoc::toc()

