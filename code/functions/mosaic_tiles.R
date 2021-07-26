mosaic_tiles <- function(tiledir, chunksize1, chunksize2, ID) {
  
  library(terra)
  
  tile_paths <- list.files(tiledir, full.names=T)
  
  # exclude any extra files
  tile_paths <- tile_paths[!grepl(tile_paths, pattern= ".tif.aux")]
  tile_paths <- tile_paths[!grepl(tile_paths, pattern= "MegaTile")]
  tile_paths <- tile_paths[!grepl(tile_paths, pattern= "Final")]
  
  if (length(tile_paths) > 1) {
    tile_list <- vector("list", length(tile_paths))
    
    for (i in 1:length(tile_paths)) {
      tile_list[[i]] <- terra::rast(tile_paths[i])
    }
    
    end <- length(tile_list)
    
    for (i in 1:ceiling(end/chunksize1)) {
      
      #  split tile_list, each with x tiles or fewer (x = chunksize1)
      if (i == 1 & end < chunksize1) {
        assign(x=paste0('args', i), value=tile_list[1:end]) # if there are less than chunksize1 tiles, args 1:max
      } else if (i == 1 & end >= chunksize1) {
        assign(x=paste0('args', i), value=tile_list[1:(chunksize1*i)]) # if there are more than chunksize1 tiles, args1 = 1:chunksize1
      } else if (i > 1 & i < ceiling(end/chunksize1)) {
        assign(x=paste0('args', i), value=tile_list[(chunksize1*(i-1)+1):(chunksize1*i)]) # middle args list = end of previous + 1:next increment of chunksize1
      } else {
        assign(x=paste0('args', i), value=tile_list[(chunksize1*(i-1)+1):end]) # last args list = end of previous + 1:end
      }
      
      # if the last list is only 1 tile, join this tile with the previous mega-tile
      if (length(get(paste0('args', i))) < 2) {
        assign(x=paste0('args', i-1), value=tile_list[(chunksize1*(i-2)+1):end]) # add orphan tile to the previous list
        
        # re-do the previous mega-tile to add in the last orphaned small tile
        assign(x=paste0('MT', i-1), value=rlang::exec("mosaic", !!!get(paste0('args', i-1)), fun='mean',
                                                      filename=paste0(tiledir, '/', ID, "_MegaTile", i-1, '.tif'), overwrite=T))
      } else {
        
        # for the list of chunksize1 or fewer tiles, execute mosaic to create a mega-tile
        assign(x=paste0('MT', i), value=rlang::exec("mosaic", !!!get(paste0('args', i)), fun='mean',
                                                    filename=paste0(tiledir, '/', ID,"_MegaTile", i, '.tif'), overwrite=T))
      }
    }
    
    logger::log_info('Finished creating mega-tiles.')
    
    mega_tiles <- mget(gtools::mixedsort(ls(pattern='MT.'))) # include function to sort mega-tile objects so the mega-mega tiles are contiguous blocks
    names(mega_tiles) <- NULL # remove names in list of mega-tiles (messes up mosaic execution for some reason)
    
    # mosaic mega-tiles to make one big raster!
    
    # if there are multiple, but less than 10 mega-tiles, mosaic them all together
    if (length(mega_tiles) > 1 & length(mega_tiles) < 10) {
      wholemap <- rlang::exec("mosaic", !!!mega_tiles, fun='mean',
                              filename=paste0(tiledir, '/', ID, 'FinalRaster.tif'), overwrite=T)
      
      # if only one mega-tile, just write this one
    } else if (length(mega_tiles) == 1) {
      terra::writeRaster(MT1, filename=paste0(tiledir, '/', ID, 'FinalRaster.tif'), overwrite=T)
      
      # if there are lots of mega-tile (> 10), put some of these together before doing final merge
    } else if (length(mega_tiles) >= 10){
      end2 <- length(mega_tiles)
      
      # split the list of mega-tiles into groups of chunksize2 tiles
      for (i in 1:ceiling(end2/chunksize2)) {
        
        #  split merged_tiles data frame into lists, each with chunksize2 tiles or fewer
        if (i == 1 & end2 < chunksize2) {
          assign(x=paste0('args2', i), value=mega_tiles[1:end2]) # if there are less than chunksize2 tiles, argsMT 1:max
        } else if (i == 1 & end2 >= chunksize2) {
          assign(x=paste0('args2', i), value=mega_tiles[1:(chunksize2*i)]) # if there are more than chunksize2 tiles, argsMT1 = 1:chunksize2
        } else if (i > 1 & i < ceiling(end2/chunksize2)) {
          assign(x=paste0('args2', i), value=mega_tiles[(chunksize2*(i-1)+1):(chunksize2*i)]) # middle argsMT list = end2 of previous + 1:next increment of chunksize2
        } else {
          assign(x=paste0('args2', i), value=mega_tiles[(chunksize2*(i-1)+1):end2]) # last argsMT list = end2 of previous + 1:end2
        }
        
        # for the list of chunksize1 or fewer tiles, execute mosaic to create a mega-tile
        assign(x=paste0('M2T', i), value=rlang::exec("mosaic", !!!get(paste0('args2', i)), fun='mean',
                                                     filename=paste0(tiledir, '/', ID,"_MegaMegaTile", i, '.tif'), overwrite=T))
        logger::log_info('Finished creating mega-mega-tiles.')
        
      }
      
      # make a list of the mega-mega tiles
      mega2_tiles <- mget(gtools::mixedsort(ls(pattern='M2T.')))
      names(mega2_tiles) <- NULL # remove names in list of mega-tiles (messes up mosaic execution for some reason)
      
      logger::log_info('Putting together mega-tiles to make final raster.')
      
      # mosaic together mega-mega tiles
      wholemap <- rlang::exec("mosaic", !!!mega2_tiles, fun='mean', filename=paste0(tiledir, '/', ID, 'FinalRaster.tif'), overwrite=T)
      logger::log_info('Final raster is complete.')
      
    }
  } else if (length(tile_paths) ==1) {
    singletile <- terra::rast(tile_paths)
    terra::writeRaster(singletile, filename=paste0(tiledir, '/', ID, 'FinalRaster.tif'), overwrite=T)
  }
  
}