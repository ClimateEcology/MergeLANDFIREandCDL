mosaic_tiles <- function(tiledir, chunksize1, chunksize2, ID, outdir, season=NA, compress=T) {
  
  library(terra)
  source('./code/functions/calc_tile_clusters.R')
  
  tile_paths <- list.files(tiledir, full.names=T)
  
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
    clusters <- calc_tile_clusters(tile_list, chunksize=chunksize1, plot_clusters=T)
    ngroups <- length(unique(clusters))
    
    ##### create mega tiles by executing mosaic respecting cluster membership
    for (i in i:ngroups) {
      assign(x=paste0('args', i), value=tile_list[clusters == i]) 
      
      # execute mosaic to create a mega-tile
      # assign(x=paste0('MT', i), value= base::eval(rlang::call2("mosaic", !!!get(paste0('args', i)), .ns="terra", fun='mean',
      #                                                          filename=paste0(tiledir, '/', ID,"_MegaTile", i, '.tif'), overwrite=T)))
      assign(x=paste0('MT', i), value= base::eval(rlang::call2("mosaic", !!!get(paste0('args', i)), .ns="terra", fun='mean'
                                                               )))
    }
    
    logger::log_info('Finished creating mega tiles.')
    
    
    # load mega tiles into list to create mega-mega tiles (if necessary) OR final raster
    mega_tiles <- mget(gtools::mixedsort(ls(pattern='MT.')))
    names(mega_tiles) <- NULL # remove names in list of mega tiles (messes up mosaic execution for some reason)
    
    # assign mega tiles to clusters based on lat/long
    clusters2 <- calc_tile_clusters(mega_tiles, chunksize=chunksize2, plot_clusters=T)
    ngroups2 <- length(unique(clusters2))
    
    ##### create mega-mega tiles by executing mosaic respecting cluster membership
    for (i in 1:ngroups2) {
      assign(x=paste0('args2', i), value=tile_list[clusters2 == i]) 
      
      # execute mosaic to create a mega-mega tile
      # assign(x=paste0('M2T', i), value= base::eval(rlang::call2("mosaic", !!!get(paste0('args2', i)), .ns="terra", fun='mean',
      #filename=paste0(tiledir, '/', ID,"_MegaMegaTile", i, '.tif'), overwrite=T)))
      assign(x=paste0('M2T', i), value= base::eval(rlang::call2("mosaic", !!!get(paste0('args2', i)), .ns="terra", fun='mean'
            )))
    }
    
    # load mega-mega tiles into list to create final raster
    mega_mega_tiles <- mget(gtools::mixedsort(ls(pattern='M2T.')))
    names(mega_mega_tiles) <- NULL # remove names in list of mega-mega tiles (messes up mosaic execution for some reason)
    
    # mosaic mega tiles to make one big raster!
    
    # if there are multiple mega-mega tiles mosaic them all together
    if (length(mega_mega_tiles) > 1) {
      if (compress == T) {
      wholemap <- base::eval(rlang::call2("mosaic", !!!mega_mega_tiles, .ns="terra", fun='mean',
                              filename=paste0(outdir, '/', ID, '_FinalRasterCompress.tif'), overwrite=T, 
                              wopt= list(gdal=c("COMPRESS=DEFLATE", "PREDICTOR=3"))))
      } else {
      wholemap <- base::eval(rlang::call2("mosaic", !!!mega_mega_tiles, .ns="terra", fun='mean',
                                            filename=paste0(outdir, '/', ID, '_FinalRaster.tif'), overwrite=T))
      }
      
      # if only one mega-mega tile, just write this one
    } else if (length(mega_mega_tiles) == 1) {
      if (compress == T) {
      terra::writeRaster(M2T1, filename=paste0(outdir, '/', ID, '_FinalRasterCompress.tif'), overwrite=T, 
                         wopt= list(gdal=c("COMPRESS=DEFLATE", "PREDICTOR=3")))
      } else {
        terra::writeRaster(M2T1, filename=paste0(outdir, '/', ID, '_FinalRaster.tif'), overwrite=T)
      }
    }
  }
      logger::log_info('Final raster is complete.')
}