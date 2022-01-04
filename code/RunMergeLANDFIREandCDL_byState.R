rm(list=ls())

# import function to merge together CDL and LANDFIRE tiles
source('./code/functions/merge_landfire_cdl_4tiles.R')
source('./code/functions/mosaic_tiles.R')
source('./code/functions/grid_rasters.R')

library(dplyr);  library(raster); library(sf); library(logger); library(future)

args <- commandArgs(trailingOnly = T)

# specify input parameters
CDLYear <- args[2] # year of NASS Cropland Data Layer
regionName <- args[3] # region to process
mktiles <- args[4]
runmerge <- args[5]
allstates <- args[6]

intermediate_dir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL' # directory to store intermediate tiles
valdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/ValidationData' # directory to store validation results (.txt files)
datadir <- './data' # directory where tabular and spatial data are stored
buffercells <- c(3,3)  # number of cells that overlap between raster tiles (in x and y directions)
writetiles <- T
target_area <- 1000 # desired size (in km2) of each tile
nvc_agclasses <- c(7960:7999) # classes in LANDFIRE NVC that are agriculture

# If all states is NOT true, use regionName <- 'National" to specify groups of states that don't match pre-defined regions

# make list of states to run (either all in shapefile or manually defined)
if (allstates == TRUE) {
  # load shapefile for state/region 
  regionalextent <- sf::st_read(paste0(datadir,'/SpatialData/', regionName , '.shp'))
  states <- regionalextent$STUSPS
} else if (allstates == FALSE) {
  if (regionName == 'Midwest') {
    states <- c('KS') # states/region to run
  } else if (regionName == 'Northeast') {
    states <- c('NY')
  } else if (regionName == 'West') {
    states <- c('WA')
  } else if (region == 'Southeast') {
    states <- c('TX_West')
  } 
}


for (stateName in states) {
  
  if (stateName %in% c('TX_East', 'TX_West')) {
    target_area <- 2000
  }
  
  logger::log_info(paste0('Starting ', stateName, '.'))
  logger::log_info(paste0('Current memory used by R is ', lobstr::mem_used(), " B."))
  
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
  
  if (is.na(xdiv)| as.numeric(xdiv) == 0) {
    xdiv <- 1
  }
  if (is.na(ydiv) | as.numeric(ydiv) == 0) {
    ydiv <- 1
  }
  # what is the resulting area of tiles using these x and y division factors?
  ntiles <- ydiv*xdiv; result_area <- areabb/ntiles
  
  # Log division factor and tile size selected for this run.
  logger::log_info(paste0('Division factor is c(', xdiv, ',', ydiv, ') which creates tiles of approximately ', round(result_area), ' km.'))
  
  
  ##### derived parameters 
  tiledir <- paste0(intermediate_dir, "/", stateName, "Tiles_", ntiles)
  nvc_path <- paste0(datadir, '/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
  cdl_path <- paste0(datadir, '/SpatialData/CDL/', CDLYear, '_30m_cdls.img')
  ID <- paste0(stateName, '_CDL', CDLYear,'NVC')
  
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
  if (mktiles == T) {
    tiles <- grid_rasters(rasterpath=c(cdl_path, nvc_path),
                                rasterID=c(paste0('CDL', CDLYear), 'NVC'),
                                regionalextent=regionalextent, tiledir=tiledir,
                                div=c(xdiv, ydiv), buffercells=buffercells,
                                NAvalues=c(0,-9999), writetiles=writetiles)
  
    save(tiles, file=paste0(tiledir,'/tiles_CDL', CDLYear, '.RDA'))
    
    logger::log_info('LANDFIRE and CDL tiles saved.')
  }
  ######################################################################################################
  ##### Part 2: Merge Individual CDL and NVC Tiles
  
  # load list of raster tiles
  load(paste0(tiledir,'/tiles_CDL', CDLYear, '.RDA'))
  
  logger::log_info('Successfully loaded list of CDL and LANDFIRE tile pairs.')
  
  if (runmerge == T) {
    #turn on parallel processing for furrr package
    future::plan(multisession)
    
    logger::log_info('Starting furrr section, parallel execution of merge_landfire_cdl function.')
    
    # loop through list of tiles in parallel with furrr::future_walk function
    # for some reason, furrr:future_map doesn't return the list of rasters
    # so, we use furrr:walk to generate the files, then read them again
    furrr::future_walk(.x=tiles, .f=merge_landfire_cdl,
                       datadir=datadir, tiledir=tiledir, valdir=valdir, veglayer='nvc', CDLYear=CDLYear,
                       buffercells=buffercells, verbose=F, nvc_agclasses=nvc_agclasses, ID=ID,
                       .options=furrr::furrr_options(seed = T))
    
    # stop parallel processing
    future::plan(sequential)
    
    logger::log_info('Completed merge for all tiles.')
  }
  
  logger::log_info('Starting mosaic operation.')

  ######################################################################################################
  ##### Part 3: Stitch together all the merged tiles

  # it is faster to mosaic in chunks, then mosaic the bigger pieces together
  # here I split into vectors of 30 tiles each, stitch these together into 'mega-tiles' then mosaic all the mega-tiles together.
  # read in tiles created by furrr
  
  # run function to mosaic tile into one larger
  mosaic_tiles(tiledir=paste0(tiledir, "/MergedCDLNVC"), chunksize1=40, chunksize2=5, ID=ID, outdir=tiledir)
  
  logger::log_info(paste0('Mosaic of ', stateName, ' tiles are complete!'))
  logger::log_info(paste0('Current memory used by R is ', lobstr::mem_used(), " B."))
  
}
