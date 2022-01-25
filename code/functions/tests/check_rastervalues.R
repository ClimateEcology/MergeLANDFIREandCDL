
# check values in raster are all present in raster attribute table

library(terra)

CDLYear <- 2019; stateName <- 'NY'
outdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/'
statedir <- paste0(outdir,'/StateRasters/', CDLYear)
ID <- paste0('CDL', CDLYear,'NVC')
nationalpath <- paste0(statedir, "/", ID, "_NationalRaster_Tier3.tif")
statepath<- paste0(statedir,"/", stateName , "_", ID, ".tif")


nationalo <- terra::rast(nationalpath)
stateo <- terra::rast(statepath)

# save a list of unique values in national raster
#state_classes <- terra::unique(stateo)
national_classes <- terra::unique(nationalo)
