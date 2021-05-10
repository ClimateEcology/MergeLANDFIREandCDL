# function to split CDL and LANDFIRE regional or national rasters into gridded tiles

grid_rasters <- function(rpath, regionalextent=NA, 
                        tile_dir, div, buffercells=c(0,0),
                        skipNAtiles = T, NAvalue, 
                        writetiles = T, ...) {
  
  ######################################################################################################
  ##### Part 1: Setup and load data
  
  # lOad libraries
  library(future); library(foreach)
  
  #separate file paths to CDL and vegetation rasters. 
  cdl_path <- rpath[1]
  
  # if only one raster path is supplied, set veg_path to NA
  if (length(rpath > 1)) {
    veg_path <- rpath[2]
  } else {
    veg_path <- NA
  }
  
  #set up logger to write status updates
  library(logger)
  logger::log_threshold(DEBUG)
  
  # load raster1
  # We will use raster object to re-project state polygons
  cdl <- raster::raster(cdl_path)
  
  # if necessary, download polygon layer of state boundaries
  if (!any(is.na(regionalextent)) & is.character(regionalextent)) {
    logger::log_info('Re-projecting regional shapefile to match CDL raster.')
    
    # download shapefile of US states
    region <- tigris::states() %>% dplyr::filter(NAME %in% regionalextent) %>%
      sf::st_transform(crs = sf::st_crs(cdl)) # re-project polygon layer to match raster1
    
  } else if ('sf' %in% class(regionalextent)) {
    region <- sf::st_transform(regionalextent, crs = sf::st_crs(cdl))
  }
  
  ######################################################################################################
  ##### Part 2: Crop national raster(s) to regional extent
  
  # create directory for output files if it doesn't already exist
  if (!dir.exists(tile_dir)) {
    dir.create(tile_dir)
  }
  
  
  # read input raster and crop to extent of provided shapefile
  # use the terra package because it is faster than raster. 
  if (!any(is.na(regionalextent))) {
    
    tictoc::tic()
    logger::log_info('Cropping national raster(s) to shapefile extent (if regionalextent is provided).')
    
    region_cdl <- terra::rast(cdl_path) %>%
      terra::crop(y=region) %>%
      raster::raster()   # convert to a raster object so the SpaDES package works

    
    if (!is.na(veg_path)) {
      region_nvc <- terra::rast(nvc_path) %>%
        terra::crop(y=region) %>%
        raster::raster()   # convert to a raster object so the SpaDES package works

    }
    
      tictoc::toc()
  }
  
  ######################################################################################################
  ##### Part 3: Split raster1 into tiles 
  
  logger::log_info('Splitting regional raster into specified number of tiles (n = xdiv * ydiv).')
  
  
  # set up parallel processing cluster (will be used by splitRaster function)
  cl <- parallel::makeCluster(parallel::detectCores() - 2)  # use all but 2 cores
  
  tictoc::tic()
  
  # split raster1 into tiles using a regular grid
  cdl_tiles <- SpaDES.tools::splitRaster(r=region_cdl, nx=div[1], ny=div[2], 
                                         buffer=buffercells, cl=cl)
  
  ######################################################################################################
  ##### Part 4: If raster2 file path is provided, split raster2 into tiles
  
  if (!is.na(veg_path)) {
    nvc_tiles <- SpaDES.tools::splitRaster(r=region_nvc, nx=div[1], ny=div[2], 
                                         buffer=buffercells, cl=cl)
  tictoc::toc()
  
  
  ######################################################################################################
  ##### Part 5: Identify background tiles that are all NA (if skipNAtiles == T)
  
  if (skipNAtiles == T) {
    
    # save lists of which raster tiles are all NA values (cdl == 0 & nvc == -9999)
    # We don't need to process raster tiles that are completely NA values (background)
    # I use the purrr map function because it nicely applies a function over a list, which is the format returned by splitRaster

    #turn on parallel processing for furrr package
    future::plan(multisession)
    
    tictoc::tic()
    # list of tiles to skip for raster1
    todiscard_cdl <- furrr::future_map(.x=cdl_tiles, .f = function(x) {
      raster::cellStats(x, stat=max) == NAvalue[1] },
      .options = furrr::furrr_options(seed = TRUE)) %>% unlist()
    # list of tiles to skip for raster2
    todiscard_nvc <- furrr::future_map(.x=nvc_tiles, .f = function(x) {
      raster::cellStats(x, stat=max) == NAvalue[2] },
      .options = furrr::furrr_options(seed = TRUE)) %>% unlist()
    tictoc::toc()

    
    # if NA tiles from raster1 and raster2 perfectly match, discard them and keep the rest
    if (all(todiscard_cdl == todiscard_nvc)) {
      
      input_rasters <- furrr::future_map2(.x= purrr::discard(cdl_tiles, todiscard_nvc), 
                                  .y= purrr::discard(nvc_tiles, todiscard_nvc), .f=c)
      
    } else if (any(todiscard_cdl != todiscard_nvc)) {
      
      # if NA tiles from raster1 and raster2 do NOT totally match, only discard tiles that are all NA in BOTH layers
      
      warning('Raster1 and Raster2 100% background tiles do not match. 
           The boundaries (e.g. land/water) of these rasters are probably different.
           Look at the tiles in the mismatched tiles folder.')
      
      input_rasters <- furrr::future_map2(.x= purrr::discard(cdl_tiles, todiscard_nvc&todiscard_cdl), 
                                   .y= purrr::discard(nvc_tiles, todiscard_nvc&todiscard_cdl), .f=c)
      
      # create directory for mismatched tiles
      if (!dir.exists(paste0(tile_dir, "/MismatchedBorderTiles/"))) {
        dir.create(paste0(tile_dir, "/MismatchedBorderTiles/"))
      }
      
      # write .tif files of CDL and NVC tiles that do NOT match 
      # (no match = one layer is all background, but the other has values other than NA)
      for (i in which(todiscard_cdl != todiscard_nvc)) {

        raster::writeRaster(cdl_tiles[[i]], paste0(tile_dir, "/MismatchedBorderTiles/CDL", 
                                                   CDLYear, "Tile", i, ".tif"), overwrite=T)
        
        if (!is.na(veg_path)) {
          raster::writeRaster(nvc_tiles[[i]], paste0(tile_dir, "/MismatchedBorderTiles/NVCTile", 
                                                   i, ".tif"), overwrite=T)
        }
      }
      
      # write raster tiles that are NOT all background in at least one layer

      if (writetiles == T) {
        logger::log_info('Writing output tiles.')
        
        # set up parallel processing cluster
        cl <- parallel::makeCluster(parallel::detectCores() - 2)  # use all but 2 cores
        parallel::clusterExport(cl=cl, envir=environment(), varlist=c('region_cdl', 'region_nvc'))
        doParallel::registerDoParallel(cl)  # register the parallel backend
        
        
        foreach::foreach(i= which(!(todiscard_nvc&todiscard_cdl))) %dopar% {
          
          #create CDL and NVC tile folders if they don't already exist
          if (!dir.exists(paste0(tile_dir, "/CDL"))) {
            dir.create(paste0(tile_dir, "/CDL"))
            dir.create(paste0(tile_dir, "/NVC"))
          }
          
          raster::writeRaster(cdl_tiles[[i]], paste0(tile_dir, "/CDL/CDL", CDLYear, "Tile", i, ".tif"), overwrite=T)
          
          if (!is.na(veg_path)) {
            raster::writeRaster(nvc_tiles[[i]], paste0(tile_dir, "/NVC/NVCTile", i, ".tif"), overwrite=T)
          }
        }
        
      }
    }
    
  } else if (skipNAtiles == F) {
    
    if (!is.na(veg_path)) {
    #turn on parallel processing for furrr package
    future::plan(multisession)
    
    # convert raster tiles to a list (each list element has 2 rasters)
    input_rasters <- furrr::future_map2(.x= cdl_tiles, .y= nvc_tiles, .f=c)
    
    }
  
    # save raster tiles as .tif files
    if (writetiles == T) {
      logger::log_info('Writing output tiles.')
      
      # set up parallel processing cluster
      cl <- parallel::makeCluster(parallel::detectCores() - 2)  # use all but 2 cores
      parallel::clusterExport(cl=cl, envir=environment(), varlist=c('region_cdl', 'region_nvc'))
      doParallel::registerDoParallel(cl)  # register the parallel backend
  
      
      foreach::foreach(i=1:length(cdl_tiles)) %dopar% {
        
        #create CDL and NVC tile folders if they don't already exist
        if (!dir.exists(paste0(tile_dir, "/CDL"))) {
          dir.create(paste0(tile_dir, "/CDL"))
          dir.create(paste0(tile_dir, "/NVC"))
        }
        
        raster::writeRaster(cdl_tiles[[i]], paste0(tile_dir, "/CDL", CDLYear, "/CDLTile", i, ".tif"), overwrite=T)
        
        if (!is.na(veg_path)) {
          raster::writeRaster(nvc_tiles[[i]], paste0(tile_dir, "/NVC/NVCTile", i, ".tif"), overwrite=T)
        }
      }
      
    }
  }
  
  parallel::stopCluster(cl); future::plan(sequential)
  
  logger::log_info('Gridding function complete, returning pairs of raster tiles as a list.')
  
  return(input_rasters)
  
  } else if (is.na(veg_path)) {
    
    logger::log_info('Gridding function complete, returning raster tiles as a list.')
    return(cdl_tiles)
  }
  
}