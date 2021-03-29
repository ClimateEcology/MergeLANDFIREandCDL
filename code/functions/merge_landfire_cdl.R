
merge_landfire_cdl <- function(data_dir, veglayer) {
  
  library(dplyr)
  library(terra)
  
  ##### Step 0: Setup and load data
  
  # load table of LANDFIRE vegetation classes
  if (veglayer == 'evt') {
    vegclasses_key <- read.csv(paste0(data_dir, '/TabularData/US_105evt_05262011.csv')) %>%
      dplyr::mutate(VALUE = as.character(Value))
    name_column <- 'EVT_Name'; name_column <- sym(name_column)
  } else if (veglayer == 'nvc') {
    vegclasses_key <- read.csv(paste0(data_dir, '/TabularData/LF_200NVC_05142020.csv')) %>%
      dplyr::mutate(VALUE = as.character(VALUE))
    
    name_column <- 'NVC_Name'; name_column <- sym(name_column)
  }
  
  # read CDL class names
  cdl_classes <- read.csv(paste0(data_dir, '/TabularData/NASS_classes_simple.csv')) %>% 
    dplyr::filter(VALUE < 500)  %>%#filter out CDL classes that I created for a different project
    dplyr::mutate(VALUE = as.character(-VALUE))
  
  
  ##### Step 1: Assign pixels that exactly match
  
  # Assign CDL agricultural classes to matching LANDFIRE ag class
  if (veglayer == 'nvc') {nvc_ag <- dplyr::filter(vegclasses_key, VALUE %in% c(7960:7999)) }
  
  agclass_match <- read.csv(paste0(data_dir, '/TabularData/CDL_NVC_AgClassMatch.csv')) %>%
    dplyr::filter(GROUP == 'A') %>%
    dplyr::select(VALUE, CLASS_NAME, GROUP, NVC_Match1, NVC_Match3)
  
  
  wheat <- dplyr::filter(agclass_match, NVC_Match1 == 'Wheat') %>% dplyr::pull(CLASS_NAME)
  
  orchard <- dplyr::filter(agclass_match, NVC_Match1 == 'Orchard') %>% dplyr::pull(CLASS_NAME)
  
  vineyard <- dplyr::filter(agclass_match, NVC_Match1 == 'Vineyard') %>% dplyr::pull(CLASS_NAME)
  
  row_crop <- dplyr::filter(agclass_match, grepl(NVC_Match1, pattern= 'Row Crop') | 
                              grepl(NVC_Match3, pattern= 'Row Crop')) %>%
    dplyr::pull(CLASS_NAME)
  
  close_grown_crop <- dplyr::filter(agclass_match, grepl(NVC_Match1, pattern= 'Close Grown Crop') | 
                                      grepl(NVC_Match3, pattern= 'Close Grown Crop')) %>%
    dplyr::pull(CLASS_NAME)
  
  
  # Assign agricultural classes in LANDFIRE raster to class from CDL
  evt <- terra::rast(paste0(data_dir, '/SpatialData/LandFire_EVegType10.tif'))
  nvc <- terra::rast(paste0(data_dir, '/SpatialData/LandFire_NatVegClassification.tif'))
  cdl <- terra::rast(paste0(data_dir, '/SpatialData/USDA_CDL_2016_FingerLakes.tif'))
  
  habitat_groups <- c('orchard', 'vineyard', 'row_crop', 'close_grown_crop', 'wheat')
  source('./code/functions/CapStr.R')
  
  
  for (habitat_name in habitat_groups) {
    
    # replace NVC orchard class with CDL fruit tree types (when they overlap)
    nvc_tochange <- dplyr::filter(nvc_ag, grepl(NVC_Name, 
      pattern= CapStr(gsub(habitat_name, pattern="_", replacement=" ")))) %>% 
      dplyr::pull(VALUE)
    
    cdl_toadd <- dplyr::filter(cdl_classes, CLASS_NAME %in% get(habitat_name)) %>% 
      dplyr::mutate(VALUE = (as.numeric(VALUE)*-1)) %>%
      dplyr::pull(VALUE)
    
    if (habitat_name == habitat_groups[[1]]) {
      veglayer_copy <- nvc
    }
    
    # create binary layer indicating landfire and cdl match
    both_orchard <- (cdl %in% cdl_toadd & veglayer_copy %in% as.numeric(nvc_tochange))

    remove <- (!both_orchard) * veglayer_copy
    add <- both_orchard * (-cdl)
    veglayer_copy <- remove + add
    print(paste0('finished ', habitat_name))
  }
  
  
  ##### Step 2: Assign mismatched pixels based on neighborhood
  
  # When possible, reassign remaining NVC ag classes by looking at surrounding cells
  temp <- veglayer_copy
  
  reclass <- data.frame(agveg=c(7970, 7971, 7972, 7973, 7974, 7975, 7978), to=NA)
  temp2 <- terra::classify(temp, rcl=reclass)

  source('./code/functions/reassign_NA.R')
  
  crops <- as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])
  
  #Is the option to define crop classes working?
  nvc_gapsfilled <- reassign_NA(map=temp2, xpct=c(0, 1), ypct=c(0, 1), 
                     window_size=7, crops=crops)
  
  sort(unique(values(nvc_gapsfilled)[values(nvc_gapsfilled) < 0]))

  ##### Step 3: Save merged raster file
  
  terra::writeRaster(nvc_gapsfilled, 
    paste0(data_dir, '/SpatialData/output/NVC_CDL2016.tif'), overwrite=T)
  
}