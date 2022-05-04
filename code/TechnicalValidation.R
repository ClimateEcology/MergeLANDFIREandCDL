# technical validation looking at the distribution of mis-matched pixels in merge CDL and LANDFIRE workflow
library(dplyr); library(future)
source('./code/functions/addcounty.R')

args <- commandArgs(trailingOnly = T)
parallel <- args[2] # aggregate data using parallel processing
nprocess <- as.numeric(args[3])
  
if (parallel == T) {
  increment <- max(2, round(nprocess/20, digits=0))
  par_text <- 'parallel'
} else if (parallel == F) {
  increment <- max(2, round(nprocess/50, digits=0))
  par_text <- 'notparallel'
}

valdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/ValidationData/'

# save necessary spatial information

# load NVC raster (just to grab projection information)
nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')
target_crs <- raster::crs(nvc)

counties <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
  dplyr::select(STATE, COUNTY, FIPS) %>%
  dplyr::filter(!is.na(COUNTY)) # take out polygons that form coasts but are not actually land area (e.g. great lakes)
  
if (nprocess == 'all') {
  tiles <- list.files(valdir, full.names = T)
} else {
  tiles <- list.files(valdir, full.names = T)[1:nprocess]
}

h <- seq(from=1, to=length(tiles), by=increment)

logger::log_info('start')

for (j in h) {
  torun <- c(j:(j+ (increment-1)))
  
  # if the last group exceed the number of files, shorten the list
  if (any(torun > length(tiles))) {
    torun <- torun[1]:length(tiles)
  }
  
  if (parallel == T) {
    #turn on parallel processing for furrr package
    future::plan(multisession)
    
    # loop through list of points in parallel with furrr::future_walk function
    assign(x=paste0('group', j), value= 
             furrr::future_map_dfr(.x=tiles[torun], .f=addcounty,
                       prj=target_crs, shape=counties,
                       .options=furrr::furrr_options(seed = T))
    )
    
    # stop parallel processing
    future::plan(sequential)
    
    logger::log_info(paste0(j,' files out of ', max(h), ' are finished.'))
    
  } else if (parallel == F) {
    for (i in torun) {
      # load csv of mismatch pixel data for one tile
      ex <- addcounty(tiles[i], prj=target_crs, shape=counties)
      
      if (i == torun[1]) {
        all <- ex
      } else {
        assign(x=paste0('group', j), value=rbind(all, ex)) # combine info for all tiles into one file
      }
    }
    logger::log_info(paste0(j,' files out of ', max(h), ' are finished.'))
  }
}

for (i in 1:length(h)) {

  # paste together results
  one <- get(paste0('group', h[i]))

  if (i == 1) {
    all <- one
  } else {
    all <- rbind(all, one) # combine info for all tiles into one file
  }
}

logger::log_info("All groups of files are combined together.")
logger::log_info("Starting summarize by state.")

cleaned <- dplyr::mutate(all, PctTile = 1/ncells_tile) %>% 
  dplyr::filter(!is.na(FIPS)) %>% # remove mis-match points that do not have FIPS code (overlap water or other non-county polygon)
  dplyr::filter(!duplicated(paste0(x, y))) # remove points that might be duplicated 
  #duplication could happen due to calculating mis-match from state tiles rather than actual state polygons, borders don't match exactly
   
freq_bystate <- cleaned %>%  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile, rm.na=T))

logger::log_info('Finished summarize by state, starting summarize by county.')

freq_bycounty <- cleaned %>% dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))

logger::log_info('Writing output files.')

if(!dir.exists(paste0('./data/TechnicalValidation/run', nprocess))) {
  dir.create(paste0('./data/TechnicalValidation/run', nprocess))
}

write.csv(freq_bystate, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatched_Cells_byState_run', 
                               nprocess,  '_group', increment, '_', par_text, '.csv'))
write.csv(freq_bycounty, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatched_Cells_byCounty_run', 
                                nprocess, '_group', increment, '_', par_text, '.csv'))
write.csv(all, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatch_ByCell_run', 
                      nprocess, '_group', increment, '_', par_text, '.csv'))

logger::log_info('Finished, processed ', nprocess, ' in groups of ', increment,'.')
