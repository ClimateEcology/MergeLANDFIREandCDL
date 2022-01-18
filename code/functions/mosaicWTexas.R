
library(terra)

args <- commandArgs(trailingOnly = T)
terra <- args[2] # year of NASS Cropland Data Layer
gdal <- args[3] # region to process
compress <- args[4] # compress output raster?

logger::log_info(paste0('terra is ', terra, ' and gdal is ', gdal))
logger::log_info('Loading tiles.')

# input parameters
CDLYear <- 2020
tiledir = outdir = '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/TX_WestTiles_414/MergedCDLNVC'
ID <- paste0('TX_West_CDL', CDLYear,'NVC')
chunksize1 <- 20
season <- NA
verbose <- T

library(terra)
source('./code/functions/calc_tile_clusters.R')

######### Initial tiles to mega-tiles!

tile_paths <- list.files(tiledir, full.names=T)
logger::log_info('Make mega: Identified ', length(tile_paths), ' raster files before filtering.')

# exclude any extra files
tile_paths <- tile_paths[!grepl(tile_paths, pattern= ".tif.aux")]
tile_paths <- tile_paths[!grepl(tile_paths, pattern= "MegaTile")]
tile_paths <- tile_paths[!grepl(tile_paths, pattern= "Final")]

if (!is.na(season)) {
  tile_paths <- tile_paths[grepl(tile_paths, pattern=season)]
}

# filter to correct year of CDL (or other ID variable, as necessary)
# this ID variable will also be included in filename of final output raster
if (!is.na(ID)) {
  tile_paths <- tile_paths[grepl(tile_paths, pattern=ID)]
}
logger::log_info('Make mega: Trying to load ', length(tile_paths), ' raster files after filtering.')

# if a state has only one tile, write single tile as final raster
if (length(tile_paths) == 1) {
  onetile <- terra::rast(tile_paths[[1]])
  
  if (compress == T) {
    terra::writeRaster(onetile, filename=paste0(outdir, '/', ID, '_FinalRasterCompress.tif'), overwrite=T, 
                       wopt= list(gdal=c("COMPRESS=DEFLATE", "PREDICTOR=3")))
  } else {
    terra::writeRaster(onetile, filename=paste0(outdir, '/', ID, '_FinalRaster.tif'), overwrite=T)
  }
}

logger::log_info('Make mega: starting mosaic-ing.')

# if a state has multiple tiles, execute hierarchical mosaic to stitch all tiles into a single raster
if (length(tile_paths) > 1) {
  
  # sort tile list so mega tiles will be adjacent (based on distance between tile centroids)
  tile_list <- vector("list", length(tile_paths))
  
  # load tile rasers into R list
  for (i in 1:length(tile_paths)) {
    tile_list[[i]] <- terra::rast(tile_paths[i])
  }
  
  end <- length(tile_list)
  
  # assign tiles to clusters based on lat/long
  clusters <- calc_tile_clusters(tile_list=tile_list, chunksize=chunksize1, plot_clusters=F)
  ngroups <- length(unique(clusters))
  
  ##### create mega tiles by executing mosaic respecting cluster membership
  for (i in 1:ngroups) {
    assign(x=paste0('args', i), value=tile_list[clusters == i]) 
    
    # execute mosaic to create a mega-tile
    base::eval(rlang::call2("mosaic", !!!get(paste0('args', i)), .ns="terra", fun='mean',
                                                             filename=paste0(tiledir, '/', ID,"_MegaTile", i, '.tif'), overwrite=T))
    if (verbose == T) {
      logger::log_info(paste0('Mega tile ', i, " is finished."))
    }
  }
  
  logger::log_info('Make mega: Finished creating mega tiles.')
  # remove some large objects from memory
  rm(tile_list); rm(tile_paths)
  rm(list=ls(pattern="args"))
  
######### Mega-tiles to final raster!

  mega_paths <- list.files(tiledir, full.names=T)
  logger::log_info('Make final: Identified ', length(mega_paths), ' raster files before filtering.')
  
  # exclude any extra files
  mega_paths <- mega_paths[!grepl(mega_paths, pattern= ".tif.aux")]
  mega_paths <- mega_paths[grepl(mega_paths, pattern= "MegaTile")]
  mega_paths <- mega_paths[!grepl(mega_paths, pattern= "MegaMega")]
  
  
  if (!is.na(ID)) {
    mega_paths <- mega_paths[grepl(mega_paths, pattern=ID)]
  }
  
  logger::log_info('Make final: Trying to load ', length(mega_paths), ' raster files after filtering.')
  
  
  mega_list <- vector("list", length(mega_paths))
  
  for (i in 1:length(mega_paths)) {
    mega_list[[i]] <- terra::rast(mega_paths[i])
  }
  logger::log_info('Loaded ', length(mega_list), ' raster files.')
  
  
  if (terra == T) {
    logger::log_info('Make final: Attempting mosaic.')
    a <- Sys.time()
    
    if (compress == T) {
    base::eval(rlang::call2("mosaic", !!!get('mega_list'), .ns="terra", fun='mean', 
                            filename=paste0(tiledir, '/', ID, '_FinalRasterCompress_terra.tif'), overwrite=T,
                            wopt= list(gdal=c("COMPRESS=DEFLATE", "PREDICTOR=3"))))
    } else if (compress == F) {
      base::eval(rlang::call2("mosaic", !!!get('mega_list'), .ns="terra", fun='mean', 
                              filename=paste0(tiledir, '/', ID, '_FinalRaster_terra.tif'), overwrite=T)) 
    }
    
    b <- Sys.time()
    
    logger::log_info(paste0("Make final: ", difftime(b,a, units="secs"), 'seconds  to execute terra mosaic.'))
  }
  
  if (gdal == T) {
    c <- Sys.time()
    gdalUtils::mosaic_rasters(gdalfile=mega_paths, dst_dataset=paste0(tiledir, '/', ID,'_FinalRaster_gdal.tif'))
    d <- Sys.time()
    
    logger::log_info(paste0("Make final: ", difftime(d,c, units="secs"), ' seconds to execute gdalUtils mosaic.'))
  }

}
