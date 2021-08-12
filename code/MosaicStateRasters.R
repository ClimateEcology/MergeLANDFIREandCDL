# join together state rasters for Beescape indices to create national maps
rm(list=ls())
laptop <- F

intermediate_dir <- '../../90daydata/geoecoservices/MergeLANDFIREandCDL'
tilestring <- '(..)Tiles'
outdir <- './data/NationalMaps'

if (laptop == T) {
  source('Z:/SCINetPostDoc/MergeLANDFIREandCDL/code/functions/mosaic_state_rasters.R')
} else if (laptop == F) {
  source('../MergeLANDFIREandCDL/code/functions/mosaic_state_rasters.R')
}

# Stitch together merged state rasters

for (CDLYear in c(2016, 2017)) {
  mosaic_state_rasters(CDLYear=CDLYear, parentdir=intermediate_dir,
    tilestring=tilestring, IDstring1=index,
    IDstring2=distance, season=season, outdir=outdir)
}
