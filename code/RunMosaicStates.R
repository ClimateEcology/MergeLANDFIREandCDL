
source('./code/functions/mosaic_states.R')

args <- commandArgs(trailingOnly = T)
message(args)

# specify input parameters
CDLYear <- args[2] # year of NASS Cropland Data Layer
tier <- unlist(stringr::str_split(args[3], pattern=":")) # which hierarchy of mosaic states to process

logger::log_info(tier)
#outdir <- 'D:/MergeLANDFIRECDL_Rasters/2017MergeCDL_LANDFIRE/' #file path on laptop

outdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/'
statedir <- paste0(outdir,'/StateRasters/', CDLYear)
ID <- paste0('CDL', CDLYear,'NVC')

mosaic_states(outdir=outdir, statedir=statedir, ID=ID, tier=tier, usepackage='gdal')

