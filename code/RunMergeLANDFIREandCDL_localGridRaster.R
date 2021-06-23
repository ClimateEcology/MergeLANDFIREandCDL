rm(list=ls())

# import function to merge together CDL and LANDFIRE tiles
source('./code/functions/merge_landfire_cdl_4tiles.R')
source('./code/functions/DEV_grid_rasters.R')

library(dplyr);  library(terra); library(sf); library(logger); library(future)

# specify input parameters
datadir <- './data' # directory where tabular and spatial data are stored
buffercells <- c(3,3)  # number of cells that overlap between raster tiles (in x and y directions)
CDLYear <- '2016' # year of NASS Cropland Data Layer
writetiles <- T
regionName <- 'NorthEast'
states <- c('DE') # states/region to run
target_area <- 900 # desired size (in km2) of each tile


for (stateName in states) {
  
  # load shapefile for state/region 
  regionalextent <- sf::st_read(paste0(datadir,'/SpatialData/', regionName , '.shp'))  %>%
    dplyr::filter(STUSPS %in% stateName)
  
  # decide how many tiles to create based on extent of shapefile
  boundary_box <- sf::st_as_sfc(sf::st_bbox((regionalextent))) # save bounding box as a polygon
  bb <- sf::st_bbox(regionalextent) # save bounding box coordinates
  ratio <- abs(bb$xmin- bb$xmax)/abs(bb$ymin- bb$ymax) # calculate ratio between length of bbox sides (x/y)
  areabb <- sf::st_area(boundary_box) * (1/(1000*1000)) # area of the bounding box in square km
  
  # calculate division factor (area bbox/desired size of each tile) and translate to nearest even number 
  ndiv <- 2 * round((areabb/target_area)/2)
  
  # approximate division factors in x and y dimensions whose product is ndiv
  ydiv <- round(sqrt(ndiv/ratio))
  xdiv <- round(ndiv/ydiv)
  
  # what is the resulting area of tiles using these x and y division factors?
  ntiles <- ydiv*xdiv; result_area <- areabb/ntiles
  
  # Log division factor and tile size selected for this run.
  logger::log_info(paste0('Division factor is c(', xdiv, ',', ydiv, ') which creates tiles of approximately ', round(result_area), ' km.'))
  
  
  ##### derived parameters 
  window_size <- (buffercells[1]*2) + 1 # diameter of neighborhood analysis window (part 2 only)
  tiledir = paste0(datadir, "/", stateName, "Tiles_", ntiles)
  evt_path <- paste0(datadir, '/SpatialData/LANDFIRE/US_105evt/grid1/us_105evt')
  nvc_path <- paste0(datadir, '/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
  cdl_path <- paste0(datadir, '/SpatialData/CDL/', CDLYear, '_30m_cdls.img')
  
  
  # read in class tables necessary in part 2
  cdl_classes <- read.csv(paste0(datadir, '/TabularData/NASS_classes_simple.csv')) %>% 
    dplyr::filter(VALUE < 500)  %>% #filter out CDL classes that I created for a different project
    dplyr::mutate(VALUE = as.character(-VALUE))
  
  # this object will be used later in 'merge_landfire_cdl.' 
  # Due to quirk of how the terra package is written, we cannot include this object as an argument to 'merge_landfire_cdl'
  # terra's 'focal' function only accepts one argument 
  allow_classes <- as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])
  
  #set up logger to write status updates
  logger::log_info('Finished setting up parameters, beginning operation to create CDL and LANDFIRE tiles.')
  
  #####################################################################################################
  ##### Part 1: Create Raster Tiles
  
  # run function to grid NE CDL and LANDFIRE into tiles (using parameters above)
  
  tiles <- DEV_grid_rasters(rasterpath=c(cdl_path, nvc_path),
                              rasterID=c(paste0('CDL', CDLYear), 'NVC'),
                              regionalextent=regionalextent, tiledir=tiledir,
                              div=c(xdiv, ydiv), buffercells=buffercells,
                              NAvalue=c(0,-9999), writetiles=writetiles)

  save(tiles, file=paste0(tiledir, '/tiles.RDA'))
  
  logger::log_info('LANDFIRE and CDL tiles saved.')
  
  ######################################################################################################
  ##### Part 2: Merge Individual CDL and NVC Tiles
  
  # load list of raster tiles
  load(paste0(tiledir, '/tiles.RDA'))
  
  logger::log_info('Successfully loaded list of CDL and LANDFIRE tile pairs.')
  
  #turn on parallel processing for furrr package
  future::plan(multisession)
  
  logger::log_info('Starting furrr section, parallel execution of merge_landfire_cdl function.')
  
  # loop through list of tiles in parallel with furrr::future_walk function
  # for some reason, furrr:future_map doesn't return the list of rasters
  # so, we use furrr:walk to generate the files, then read them again
  furrr::future_walk(.x=tiles, .f=merge_landfire_cdl,
                     datadir=datadir, tiledir=tiledir, veglayer='nvc', CDLYear=CDLYear,
                     window_size=window_size, verbose=F, .options=furrr::furrr_options(seed = TRUE))
  
  # stop parallel processing
  future::plan(sequential)
  
  # read in tiles created by furrr
  toread <- list.files(paste0(tiledir, "/MergedCDLNVC"), full.names=T)
  # exclude any extra files
  toread <- toread[!grepl(toread, pattern= ".tif.aux")]
  
  merged_tiles2 <- vector("list", length(toread))
  
  for (i in 1:length(toread)) {
    merged_tiles2[[i]] <- terra::rast(toread[i])
  }
  
  logger::log_info('Completed merge for all tiles.')
  logger::log_info('Starting mosaic operation.')

  ######################################################################################################
  ##### Part 3: Stitch together all the merged tiles

  # it is faster to mosaic in chunks, then mosaic the bigger pieces together
  # here I split into vectors of 30 tiles each, stitch these together into 'mega-tiles' then mosaic all the mega-tiles together.
  end <- length(merged_tiles2)
  
  for (i in 1:ceiling(end/30)) {
    
    #  split merged_tiles data frame into lists, each with 30 tiles or fewer
    if (i == 1 & end < 30) {
      assign(x=paste0('args', i), value=merged_tiles2[1:end])
    } else if (i == 1 & end >= 30) {
      assign(x=paste0('args', i), value=merged_tiles2[1:(30*i)])
    } else if (i > 1 & i < ceiling(end/30)) {
      assign(x=paste0('args', i), value=merged_tiles2[(30*(i-1)+1):(30*i)])
    } else {
      assign(x=paste0('args', i), value=merged_tiles2[(30*(i-1)+1):end])
    }
    
    # for the list of 30 or fewer tiles, execute mosaic to create a mega-tile
    assign(x=paste0('MT', i), value=rlang::exec("mosaic", !!!get(paste0('args', i)), fun='mean',
      filename=paste0(tiledir, '/', stateName, '_CDLNVCMerge', i, '.tif'), overwrite=T)
      )
  }
  
  logger::log_info('Mosaic of mega-tiles is complete.')
  
  mega_tiles <- mget(ls(pattern='MT.'))
  names(mega_tiles) <- NULL # remove names in list of mega-tiles (messes up mosaic execution for some reason)
  
  if (length(mega_tiles) > 1) {
    wholemap <- rlang::exec("mosaic", !!!mega_tiles, fun='mean',
      filename=paste0(tiledir, '/', stateName, '_FinalCDL', CDLYear,'NVCMerge.tif'), overwrite=T)
  } else {
   terra::writeRaster(MT1, filename=paste0(tiledir, '/', stateName, '_FinalCDL', CDLYear,'NVCMerge.tif'), overwrite=T) 
  }

  logger::log_info('Mosaic of full raster is complete!')
}
