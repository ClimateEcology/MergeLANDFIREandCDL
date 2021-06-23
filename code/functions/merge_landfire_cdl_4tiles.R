
merge_landfire_cdl <- function(datadir, tiledir, veglayer, CDLYear, tiles, window_size, verbose) {
  
  ##### Step 0: Setup and load data
  
  # specify allow_classes is a global variable (necessary for futures package to work)
  allow_classes
  
  # load table of LANDFIRE vegetation classes
  if (veglayer == 'evt') {
    vegclasses_key <- read.csv(paste0(datadir, '/TabularData/US_105evt_05262011.csv')) %>%
      dplyr::mutate(VALUE = as.character(Value))
    name_column <- 'EVT_Name'; name_column <- sym(name_column)
  } else if (veglayer == 'nvc') {
    vegclasses_key <- read.csv(paste0(datadir, '/TabularData/LF_200NVC_05142020.csv')) %>%
      dplyr::mutate(VALUE = as.character(VALUE))
    
    name_column <- 'NVC_Name'; name_column <- sym(name_column)
  }
  
  # read CDL class names
  cdl_classes <- read.csv(paste0(datadir, '/TabularData/NASS_classes_simple.csv')) %>% 
    dplyr::filter(VALUE < 500)  %>% #filter out CDL classes that I created for a different project
    dplyr::mutate(VALUE = as.character(-VALUE))
  
  if (verbose == T) {
    logger::log_info('Loaded necessary tabular and spatial data.')
    logger::log_info('Begin step 1: re-assign pixels where broad land-use class matches (e.g. CDL ag = LANDFIRE ag).')
  }
  ##### Step 1: Assign pixels that exactly match
  
  # create vectors listing which CDL classes match LANDFIRE wheat, orchard, vineyard, row crop, and close-grown crop
  if (veglayer == 'nvc') {nvc_ag <- dplyr::filter(vegclasses_key, VALUE %in% c(7960:7999)) }
  
  agclass_match <- read.csv(paste0(datadir, '/TabularData/CDL_NVC_AgClassMatch.csv')) %>%
    dplyr::filter(GROUP == 'A') %>%
    dplyr::select(VALUE, CLASS_NAME, GROUP, NVC_Match1, NVC_Match3)
  
  
  wheat <- dplyr::filter(agclass_match, NVC_Match1 == 'Wheat') %>% dplyr::pull(CLASS_NAME)
  
  orchard <- dplyr::filter(agclass_match, NVC_Match1 == 'Orchard') %>% dplyr::pull(CLASS_NAME)
  
  berries <- dplyr::filter(agclass_match, NVC_Match1 == "Bush fruit and berries") %>% dplyr::pull(CLASS_NAME)
  
  vineyard <- dplyr::filter(agclass_match, NVC_Match1 == 'Vineyard') %>% dplyr::pull(CLASS_NAME)
  
  row_crop <- dplyr::filter(agclass_match, grepl(NVC_Match1, pattern= 'Row Crop') | 
                              grepl(NVC_Match3, pattern= 'Row Crop')) %>%
    dplyr::pull(CLASS_NAME)
  
  close_grown_crop <- dplyr::filter(agclass_match, grepl(NVC_Match1, pattern= 'Close Grown Crop') | 
                                      grepl(NVC_Match3, pattern= 'Close Grown Crop')) %>%
    dplyr::pull(CLASS_NAME)
  
  # Load spatial layers (EVT, NVC, and CDL rasters)
  cdl <- terra::rast(tiles[[1]])
  nvc <- terra::rast(tiles[[2]])
  
  # check if projections of raster tiles are the same. If not, re-project them to match.
  
  if (terra::crs(cdl) != terra::crs(nvc)) {
    cdl <- terra::project(x=cdl, y=nvc)
  }
  
  
  habitat_groups <- c('orchard', 'berries', 'vineyard', 'row_crop', 'close_grown_crop', 'wheat')

  # For each habitat group, replace LANDFIRE class with CDL pixel class (but only if CDL class matches)
  for (habitat_name in habitat_groups) {
    
    # e.g replace NVC orchard class with CDL fruit tree types (when NVC orchard pixels overlap with CDL fruit tree)
    nvc_tochange <- dplyr::filter(nvc_ag, grepl(NVC_Name, 
      pattern= beecoSp::CapStr(gsub(habitat_name, pattern="_", replacement=" ")))|
      grepl(NVC_Name, pattern=habitat_name)) %>% 
      dplyr::pull(VALUE)
    
    cdl_toadd <- dplyr::filter(cdl_classes, CLASS_NAME %in% get(habitat_name)) %>% 
      dplyr::mutate(VALUE = (as.numeric(VALUE)*-1)) %>%
      dplyr::pull(VALUE)
    
    if (habitat_name == habitat_groups[[1]]) {
      veglayer_copy <- nvc
    }
    
    # create binary layer indicating landfire and cdl match
    both_orchard <- (cdl %in% cdl_toadd & veglayer_copy %in% as.numeric(nvc_tochange))
    
    if (verbose == T) {
      logger::log_info(paste0("Projection match =", terra::crs(both_orchard) == terra::crs(veglayer_copy)))
      logger::log_info(paste0("Extent match =", terra::ext(both_orchard) == terra::ext(veglayer_copy)))
    }
    
    remove <- (!both_orchard) * veglayer_copy
    add <- both_orchard * (-cdl)
    veglayer_copy <- remove + add
    if (verbose == T) { logger::log_info(paste0('finished ', habitat_name)) }
  }
  
  if (verbose == T) {
    logger::log_info('Step 1 complete.')
    logger::log_info('Begin step 2: assign mis-matched pixel via neighborhood analysis.')
  }
  ##### Step 2: Assign mismatched pixels based on neighborhood
  
  # When possible, reassign remaining NVC ag classes by looking at surrounding cells
  temp <- veglayer_copy
  
  reclass <- data.frame(agveg=c(7970, 7971, 7972, 7973, 7974, 7975, 7978), to=NA)
  temp2 <- terra::classify(temp, rcl=reclass)

  #crops <- as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])
  
  # Is the option to define crop classes working?
  nvc_gapsfilled <- beecoSp::reassign_NA(map=temp2,
                       window_size=window_size, replace_any=F)
  
  ##### Step 4: Crop merged tile to extent of original tiles (remove overlap)
  
  # create extent object that removes the buffer cells 
  delta_x <- terra::res(nvc_gapsfilled)[1]*buffercells[1]
  delta_y <- terra::res(nvc_gapsfilled)[2]*buffercells[2]
  
  # subtract buffer distance from tile extent
  original_extent <- terra::ext(c(
  terra::ext(nvc_gapsfilled)$xmin + delta_x,
  terra::ext(nvc_gapsfilled)$xmax - delta_x,
  terra::ext(nvc_gapsfilled)$ymin + delta_y,
  terra::ext(nvc_gapsfilled)$ymax - delta_y
  ))
  
  # crop tile to original extent (without buffer pixels)
  nvc_gapsfilled <- terra::crop(nvc_gapsfilled, original_extent)
  
  if (verbose == T) {
    logger::log_info('Step 2 complete.')
    logger::log_info('Save merged raster tiles.')
  }
  ##### Step 3: Save merged raster file
  if (!dir.exists(paste0(tiledir, "/MergedCDL", toupper(veglayer), "/"))) {
    dir.create(paste0(tiledir, "/MergedCDL", toupper(veglayer), "/"))
  }
  
  merged_ext <- terra::ext(nvc_gapsfilled)
  
  terra::writeRaster(nvc_gapsfilled, 
    paste0(tiledir, "/MergedCDL", toupper(veglayer), "/", 
           merged_ext[1], "_", merged_ext[3], ".tif"), overwrite=T)
  
  return(nvc_gapsfilled)
  
}
