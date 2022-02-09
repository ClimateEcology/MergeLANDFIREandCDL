# get CDL year from sbatch, shell script arguments

args <- commandArgs(trailingOnly = T)

# specify input parameters
CDLYear <- args[2] # year of NASS Cropland Data Layer


source('./code/functions/tests/check_rastersize.R')
source('./code/functions/tests/check_extent_crs.R')
source('./code/functions/tests/check_rastervalues.R')

nationaldir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRasters'
alltiledirs <- list.dirs('../../../90daydata/geoecoservices/MergeLANDFIREandCDL', recursive=F)

# use this file path if running from 90daydata
#alltiledirs <- list.dirs(getwd(), recursive=F)

alltiledirs <- alltiledirs[grepl(alltiledirs, pattern="Tiles")]

for (onedir in alltiledirs) {
  check_rastersize(onedir, cutoff_pct=0.85)
  check_extent_crs(onedir)
}

logger::log_info('Finished file size, CRS, and extent tests.')
logger::log_info('Check raster values next.')

if (CDLYear == 'all') {
  for (i in 2012:2020) {
  logger::log_info('Running all years of check values.')
  # all values in state rasters in raster attribute table?
  outdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/'
  statedir <- paste0(outdir,'/StateRasters/', i)
  res <- check_rastervalues(CDLYear = i, dir=statedir)
  # check final, national rasters too
  res <- check_rastervalues(CDLYear = i, dir=nationaldir)
  }
} else {
  logger::log_info(paste0('Running check values for ', CDLYear))
  res <- check_rastervalues(CDLYear = CDLYear, dir=statedir)
  # check final, national rasters too
  res <- check_rastervalues(CDLYear = CDLYear, dir=nationaldir)
}


