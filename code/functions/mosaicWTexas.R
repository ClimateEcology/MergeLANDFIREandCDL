
library(terra)

args <- commandArgs(trailingOnly = T)
terra <- args[2] # year of NASS Cropland Data Layer
gdal <- args[3] # region to process
  
logger::log_info(paste0('terra is ', terra, ' and gdal is ', gdal))
logger::log_info('Loading tiles.')
# input parameters
CDLYear <- 2020
tiledir = outdir = '../../../../90daydata/geoecoservices/MergeLANDFIREandCDL/TX_WestTiles_414/MergedCDLNVC'
ID <- paste0('TX_West_CDL', CDLYear,'NVC')

mega_paths <- list.files(tiledir, full.names=T)
logger::log_info('Trying to load ', length(mega_paths), ' raster files.')

# exclude any extra files
mega_paths <- mega_paths[!grepl(mega_paths, pattern= ".tif.aux")]
mega_paths <- mega_paths[grepl(mega_paths, pattern= "MegaTile")]
mega_paths <- mega_paths[!grepl(mega_paths, pattern= "MegaMega")]


if (!is.na(ID)) {
  mega_paths <- mega_paths[grepl(mega_paths, pattern=ID)]
}

logger::log_info('Trying to load ', length(mega_paths), ' raster files after filtering.')


mega_list <- vector("list", length(mega_paths))

for (i in 1:length(mega_paths)) {
  mega_list[[i]] <- terra::rast(mega_paths[i])
}
logger::log_info('Loaded ', length(mega_list), 'raster files.')


if (terra == T) {
  a <- Sys.time()
  base::eval(rlang::call2("mosaic", !!!get('mega_list'), .ns="terra", fun='mean', filename=paste0(tiledir, '/', ID, '_FinalRaster_terra.tif'), overwrite=T))
  b <- Sys.time()
  
  logger::log_info(paste0(b-a, ' seconds to execute terra mosaic.'))
}

if (gdalUtils == T) {
  c <- Sys.time()
  gdalUtils::mosaic_rasters(gdalfile=mega_paths, dst_dataset=paste0(tiledir, '/', ID,'_FinalRaster_gdal.tif'))
  d <- Sys.time()
  
  logger::log_info(paste0(d-c, ' seconds to execute gdalUtils mosaic.'))
}

