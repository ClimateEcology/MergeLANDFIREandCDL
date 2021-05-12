rm(list=ls())

library(dplyr); library(terra)

source('./code/functions/merge_landfire_cdl_4tiles.R')

# specify input parameters
veglayer <- 'nvc'
data_dir <- './data' #directory where tabular and spatial data are stored
CDLYear <- '2016'
buffercells <- c(3,3)


##### derived parameters 
tile_dir = paste0(data_dir, "/PATiles")
window_size <- (buffercells[1]*2) + 1
evt_path <- paste0(data_dir, '/SpatialData/LANDFIRE/US_105evt/grid1/us_105evt')
nvc_path <- paste0(data_dir, '/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
cdl_path <- paste0(data_dir, '/SpatialData/CDL/', CDLYear, '_30m_cdls.img')


# read CDL class names
cdl_classes <- read.csv(paste0(data_dir, '/TabularData/NASS_classes_simple.csv')) %>% 
  dplyr::filter(VALUE < 500)  %>% #filter out CDL classes that I created for a different project
  dplyr::mutate(VALUE = as.character(-VALUE))

# this object will be used later in 'merge_landfire_cdl.' 
# Due to quirk of how the terra package is written, we cannot include this object as an argument to 'merge_landfire_cdl'
# terra's 'focal' function only accepts one argument 
allow_classes <- as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])

# load list of raster tiles created by 'RunGridRaster.R'

load(paste0(tile_dir, '/tiles.RDA'))

# parallel

library(future)
#turn on parallel processing for furrr package
future::plan(multisession)

tictoc::tic()

# loop through list of tiles to merge with purrr::map function
furrr::future_walk(.x=tiles[1:2], .f=merge_landfire_cdl, 
            data_dir=data_dir,veglayer=veglayer, CDLYear=CDLYear, 
            window_size=window_size, .options = furrr::furrr_options(seed = TRUE))
tictoc::toc()


future::plan(sequential)
