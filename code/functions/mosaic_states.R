#mosaic_states <- function(statedir, chunksize1, ID, outdir, season=NA, compress=T, verbose=F) {
 
#statedir <- 'D:/MergeLANDFIRECDL_Rasters/2017MergeCDL_LANDFIRE/2017/' #file path on laptop

CDLYear <- 2019
statedir <- paste0(intermediate_dir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/StateRasters/', CDLYear)
ID <- paste0('CDL', CDLYear,'NVC')

  library(terra)
  source('./code/functions/calc_state_clusters.R')
  
  # save some strings to use later
  compress_filename <- paste0(outdir, '/', ID, '_NationalRasterCompress.tif')
  rawsize_filename <- paste0(outdir, '/', ID, '_NationalRaster.tif')
  
  # make list of files in statedir
  state_paths <- list.files(statedir, full.names=T)
  logger::log_info('Tier 1: Identified ', length(state_paths), ' raster files before filtering.')
  
  # exclude any extra files
  state_paths <- state_paths[!grepl(state_paths, pattern= ".tif.aux")]
  state_paths <- state_paths[!grepl(state_paths, pattern= "MegaTile")]
  
  # filter to correct year of CDL (or other ID variable, as necessary)
  # this ID variable will also be included in filename of final output raster
  if (!is.na(ID)) {
    state_paths <- state_paths[grepl(state_paths, pattern=ID)]
  }
  
  logger::log_info('Tier 1: Trying to load ', length(state_paths), ' raster files after filtering.')
  
  
  # if a CDL year has only one tile, write single tile as final raster
  if (length(state_paths) == 1) {
    stop('There is only one state raster for the year specified. Check input files.')
  }

    
    # sort tile list so mega tiles will be adjacent (based on distance between tile centroids)
    state_list <- vector("list", length(state_paths))
    
    # load tile rasers into R list
    for (i in 1:length(state_paths)) {
      state_list[[i]] <- terra::rast(state_paths[i])
    }
    
    # assign tiles to clusters based on lat/long
    clusters <- calc_state_clusters(state_list=state_list, tier=1, plot_clusters=T)
    ngroups <- length(unique(clusters))
    
    logger::log_info('Tier 1: starting mosaic-ing state rasters using ', ngroups, " clusters.")
    
    ##### create mega tiles by executing mosaic respecting cluster membership
    for (i in 1:ngroups) {
      assign(x=paste0('args', i), value=state_list[clusters == i]) 
      
      # execute mosaic to create a mega-tile
      base::eval(rlang::call2("mosaic", !!!get(paste0('args', i)), .ns="terra", fun='mean',
                                                               filename=paste0(statedir, '/', ID,"_NationalMegaTile", i, '_Tier1.tif'),
                                                               overwrite=T))
      if (verbose == T) {
        logger::log_info(paste0('Tier 1: Mega tile ', i, " is finished."))
      }
    }
    
    logger::log_info('Tier 1: Finished creating mega tiles.')
    
    
    # remove some large objects from memory
    rm(state_list); rm(state_paths)
    rm(list=ls(pattern="args"))
    
    ######## Mega-tiles to final raster!
    
    mega_paths <- list.files(statedir, full.names=T)
    logger::log_info('Tier 2: Identified ', length(mega_paths), ' raster files before filtering.')
    
    
    # exclude any extra files
    mega_paths <- mega_paths[!grepl(mega_paths, pattern= ".tif.aux")]
    mega_paths <- mega_paths[grepl(mega_paths, pattern= "MegaTile")]
    mega_paths <- mega_paths[!grepl(mega_paths, pattern= "MegaMega")]
    mega_paths <- mega_paths[grepl(mega_paths, pattern= paste0("_Tier1.tif"))] #filter to mega-tiles that were created in previous round
    
    if (!is.na(ID)) {
      mega_paths <- mega_paths[grepl(mega_paths, pattern=ID)]
    }
    
    logger::log_info('Tier 2: Trying to load ', length(mega_paths), ' raster files after filtering.')
    
    # load mega-tiles into list to mosaic
    mega_list <- vector("list", length(mega_paths))
    
    for (i in 1:length(mega_paths)) {
      mega_list[[i]] <- terra::rast(mega_paths[i])
    }
    
    # assign tiles to clusters based on lat/long
    clusters2 <- calc_state_clusters(state_list=mega_list, tier=2, plot_clusters=F)
    ngroups2 <- length(unique(clusters2))
    
    logger::log_info('Tier 2: starting mosaic-ing.')
    
    ##### create mega tiles by executing mosaic respecting cluster membership
    for (i in 1:ngroups2) {
      assign(x=paste0('args2', i), value=mega_list[clusters2 == i]) 
      
      # execute mosaic to create a mega-tile
      base::eval(rlang::call2("mosaic", !!!get(paste0('args2', i)), .ns="terra", fun='mean',
                              filename=paste0(statedir, '/', ID,"_NationalMegaTile", i, '_Tier2.tif'),
                              overwrite=T))
      if (verbose == T) {
        logger::log_info(paste0('Tier 2: Mega tile ', i, " is finished."))
      }
    }
    
    logger::log_info('Tier 2: Finished creating mega tiles.')
    
    
#   
#       b <- Sys.time() # save end time
#       logger::log_info(paste0("Make final: Final raster exists? ", file.exists(file1)))
#       logger::log_info(paste0("Make final: ", difftime(b,a, units="mins"), ' minutes  to execute mosaic w/ terra.'))
#     }
#   
#   }
