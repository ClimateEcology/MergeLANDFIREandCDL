
source('./code/functions/mosaic_states.R')

args <- commandArgs(trailingOnly = T)

# specify input parameters
CDLYear <- args[2] # year of NASS Cropland Data Layer
tier <- args[3] # which hierarchy of mosaic states to process

#outdir <- 'D:/MergeLANDFIRECDL_Rasters/2017MergeCDL_LANDFIRE/' #file path on laptop

outdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/'
statedir <- paste0(outdir,'/StateRasters/', CDLYear)
ID <- paste0('CDL', CDLYear,'NVC')

mosaic_states(outdir=outdir, statedir=statedir, ID=ID, tier=c(1,2), usepackage='gdal')

