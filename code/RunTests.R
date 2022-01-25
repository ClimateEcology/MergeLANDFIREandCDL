# get CDL year from sbatch, shell script arguments

args <- commandArgs(trailingOnly = T)

# specify input parameters
CDLYear <- args[2] # year of NASS Cropland Data Layer


source('./code/functions/tests/check_rastersize.R')
source('./code/functions/tests/check_extent_crs.R')
source('./code/functions/tests/check_rastervalues.R')


alltiledirs <- list.dirs('../../../90daydata/geoecoservices/MergeLANDFIREandCDL', recursive=F)

# use this file path if running from 90daydata
#alltiledirs <- list.dirs(getwd(), recursive=F)

alltiledirs <- alltiledirs[grepl(alltiledirs, pattern="Tiles")]

for (onedir in alltiledirs) {
  check_rastersize(onedir, cutoff_pct=0.85)
  check_extent_crs(onedir)
}

# are all values in state rasters in raster attribute table?
#res2019 <- check_rastervalues(CDLYear = CDLYear)