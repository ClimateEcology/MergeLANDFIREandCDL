# Tabulate pixel frequency for NVC by state and county

source('./code/functions/tabulate_pixels_bycounty.R')
source('./code/functions/tabulate_pixels_bystate.R')

# file path to boundary shapefiles
statepath <- './data/SpatialData/National.shp'
countypath <- './data/SpatialData/us_counties_better_coasts.shp'

# file path to national raster
nvc <- raster::raster('./data/SpatialData/LANDFIRE/US_200NVC/Tif/us_200nvc.tif')

# where to save output csv
state_out <-  './data/NVC_StatePixelFreq.csv'
county_out <- './data/NVC_CountyPixelFreq.csv'


# run 
tabulate_pixels_bycounty(rastpath=nvc, countypath=countypath, outpath=county_out)
tabulate_pixels_bystate(rastpath=nvc, statepath=statepath, outpath=state_out)