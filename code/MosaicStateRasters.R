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
# provide all CDL year we might possibly want. Mosaic function will skip those with no available rasters.
for (CDLYear in c(2012:2020)) { 
  for (index in c('Forage', 'Insecticide')) {
    
    mosaic_state_rasters(CDLYear=CDLYear, parentdir=intermediate_dir,
      tilestring=tilestring, IDstring1=index,
      IDstring2=distance, season=season, outdir=outdir)
    
  }
}
