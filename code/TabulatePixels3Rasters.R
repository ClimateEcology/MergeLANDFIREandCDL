# Tabulate pixel frequency for NVC by state and county

source('./code/functions/tabulate_pixels_bycounty.R')
source('./code/functions/tabulate_pixels_bystate.R')

# file path to boundary shapefiles
statepath <- './data/SpatialData/National.shp'
countypath <- './data/SpatialData/us_counties_better_coasts.shp'

# get CDL year from sbatch file
args <- commandArgs(trailingOnly = T)
CDLYear <- args[2] # year of NASS Cropland Data Layer

# for one year of CDL, run NVC also
if (CDLYear == 2012) {
  i <- 'NVC'
  rastpath <- './data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif'
  # where to save output csv
  state_out <-  paste0('./data/PixelFreq/', i, '_StatePixelFreq.csv')
  county_out <- paste0('./data/PixelFreq/', i, '_CountyPixelFreq.csv')
  
  ##### tabulate NVC
  tabulate_pixels_bycounty(rastpath=rastpath, countypath=countypath, outpath=county_out)
}

#  cross-tab CDL and merged CDL/NVC for every year
for (i in c('CDL', 'MergedCDLNVC')) {

  # file path to national raster
  if (i == 'CDL') {
    # set CDL path to national rasters with altered NA values (for years when that was necessary)
    # else CDL path is national raster unaltered from USDA NASS
    if (file.exists(paste0('./data/SpatialData/CDL/', CDLYear, '_30m_cdls_fixNA.img'))) {
      rastpath <- paste0('./data/SpatialData/CDL/', CDLYear, '_30m_cdls_fixNA.img')
    } else {
      rastpath <- paste0('./data/SpatialData/CDL/', CDLYear, '_30m_cdls.img')
    }
      
  } else if (i == 'MergedCDLNVC') {
    rastpath <- paste0('../../../90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRasters/CDL', CDLYear, 'NVC_NationalRaster.tif')
  }
  
  if (i == 'CDL') {
    id <- paste0(i, CDLYear)
  } else if (i == 'MergedCDLNVC') {
    id <- paste0('CDL', CDLYear,'NVC')
  }
  
  # where to save output csv
  state_out <-  paste0('./data/PixelFreq/', id, '_StatePixelFreq.csv')
  county_out <- paste0('./data/PixelFreq/', id, '_CountyPixelFreq.csv')
  
  ##### run 
  logger::log_info('Tabulating freq pixels by county for ', CDLYear,", ", i)
  tabulate_pixels_bycounty(rastpath=rastpath, countypath=countypath, outpath=county_out)

  logger::log_info('Finished ', id)
}