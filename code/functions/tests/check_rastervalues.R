
# check values in raster are all present in raster attribute table
library(terra)

check_rastervalues <- function(CDLYear, dir) {
  
  # specify string patterns for file paths
  ID <- paste0('CDL', CDLYear,'NVC')
  
  # load combined attribute table (NVC & CDL)
  rat <- read.csv('./data/TabularData/CombinedRasterAttributeTable_CDLNVC.csv')
  
  # list all state rasters in output directory that match appropriate pattern
  statepaths <- list.files(dir, pattern=paste0(".tif"), full.names = T)
  statepaths <- list.files(dir, pattern=paste0(ID), full.names = T)
  statepaths <- statepaths[!grepl(statepaths, pattern= ".tif.aux")]
  statepaths <- statepaths[!grepl(statepaths, pattern= "MegaTile")]
  statepaths <- statepaths[!grepl(statepaths, pattern= "Tier")]
  
  
  for (i in 1:length(statepaths)) {

    # extract state name from file path
    temp <- stringr::str_split(basename(statepaths[i]), pattern="_")
    temp <- temp[[1]]
    
    if (length(temp) > 2) {
      stateName <- paste0(temp[1], "_", temp[2]) # Texas east and west have _ in state name so require special treatment
    } else {
      stateName <- temp[1]
    }
    # load state raster  
    stateo <- terra::rast(statepaths[i])
    
    # save a list of unique values in national raster
    state_classes <- terra::unique(stateo)
    
    # are state raster classes in RAT?
    inrat <- state_classes[,1] %in% rat$VALUE
    
    # which raster classes are NOT in the attribute table
    classes_toflag <- state_classes[!inrat, 1]
    
    if (length(classes_toflag) > 0) {
      logger::log_info("CheckValue test failed! ", stateName, " classes not in RAT: ", classes_toflag)
    }
    
    state_out <- tibble::tibble(TestName='CheckValues', State=stateName, CDLYear=CDLYear, 
                                TestResult= dplyr::if_else(!(length(classes_toflag) > 0), 'PASS', 'FAIL'),
                                FlagClasses = dplyr::if_else((length(classes_toflag) > 0), paste0(classes_toflag, collapse = ','), 'Test passed'))
    
    logger::log_info("Check ", CDLYear, " raster values: Finished ", stateName, '.')
    
    if (i == 1) {
      check_test <- state_out
    } else if (i > 1) {
      check_test <- rbind(check_test, state_out)
    }
  }
  logger::log_info('Finished raster values test.')
  return(check_test)
}