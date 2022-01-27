# Tabulate pixel frequency for NVC by state and county

source('./code/functions/tabulate_pixels_bycounty.R')
source('./code/functions/tabulate_pixels_bystate.R')

# file path to boundary shapefiles
statepath <- './data/SpatialData/National.shp'
countypath <- './data/SpatialData/us_counties_better_coasts.shp'

CDLYear <- 2016 

# 'MergedCDLNVC'
#for (i in c('NVC', 'CDL')) {
for (i in c('CDL')) {
    
  # file path to national raster
  if (i == 'NVC') {
    rastpath <- './data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif'
  
    } else if (i == 'CDL') {
    # set CDL path to national rasters with altered NA values (for years when that was necessary)
    # else CDL path is national raster unaltered from USDA NASS
    if (file.exists(paste0('./data/SpatialData/CDL/', CDLYear, '_30m_cdls_fixNA.img'))) {
      rastpath <- paste0('./data/SpatialData/CDL/', CDLYear, '_30m_cdls_fixNA.img')
    } else {
      rastpath <- paste0('./data/SpatialData/CDL/', CDLYear, '_30m_cdls.img')
    }
      
  } else if (i == 'MergedCDLNVC') {
    rastpath <- ''
  }
  
  if (i == 'CDL') {
    i <- paste0(i, CDLYear)
  }
  # where to save output csv
  state_out <-  paste0('./data/PixelFreq/', i, '_StatePixelFreq.csv')
  county_out <- paste0('./data/PixelFreq/', i, '_CountyPixelFreq.csv')
  
  ##### run 
  tabulate_pixels_bycounty(rastpath=rastpath, countypath=countypath, outpath=county_out)
  #tabulate_pixels_bystate(rastpath=rastpath, statepath=statepath, outpath=state_out)

  logger::log_info('Finished ', i)
}