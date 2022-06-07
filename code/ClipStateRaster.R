library(terra); library(dplyr); library(logger)

args <- commandArgs(trailingOnly = T)

# specify input parameters
CDLYear <- args[2] # year of NASS Cropland Data Layer
regionName <- args[3] # region to process
clipstates <- args[4]
allstates <- args[5] 

if (clipstates == TRUE) {
  
  # specify input parameters
  intermediate_dir <- '/90daydata/geoecoservices/MergeLANDFIREandCDL' # directory to store intermediate tiles
  datadir <- './data' # directory where tabular and spatial data are stored
  compress <- T # compress output rasters
  
  # make list of states to run
  regionalextent <- sf::st_read(paste0(datadir,'/SpatialData/', regionName , '.shp'))
  states <- regionalextent$STUSPS

  # save vector of tile directories
  alltiledirs <- list.dirs(intermediate_dir, recursive = F)

  # narrow down to directories that have tiles (pattern = stateNameTiles_ntiles) & are in specified region
  alltiledirs <- alltiledirs[grepl(alltiledirs, pattern = paste0(states, 'Tiles', collapse="|"))]
  
  # if final raster was saved inside MergedCDLNVC, move it to base Tile directory

  for (tiledir in alltiledirs) {
    
    # make list of state's finished rasters
    files_toread <- list.files(tiledir, full.names=T)
    files_toread <- as.list(files_toread[grepl(files_toread, pattern= "FinalRasterCompress") & 
                                           grepl(files_toread, pattern = paste0("CDL", CDLYear))])
    files_toread <- files_toread[!grepl(files_toread, pattern= ".tif.aux")] # do not try to load .aux files
    files_toread <- files_toread[!grepl(files_toread, pattern= ".tif.aux.xml")] # do not try to load .aux files
    
    
    if (length(files_toread) == 0) {
      files_toread <- list.files(paste0(tiledir, "/MergedCDLNVC"), full.names=T)
      files_toread <- files_toread[grepl(files_toread, pattern= "FinalRasterCompress") & 
                                             grepl(files_toread, pattern = paste0("CDL", CDLYear))]
      files_toread <- files_toread[!grepl(files_toread, pattern= ".tif.aux")] # do not try to load .aux files
      files_toread <- files_toread[!grepl(files_toread, pattern= ".tif.aux.xml")] # do not try to load .aux files
      file.copy(from=files_toread[1], to= paste0(dirname(dirname(files_toread[1])),"/", basename(files_toread[1])) )
    }
    

    if (grepl(tiledir, pattern="TX_West")| grepl(tiledir, pattern="TX_East")) {
      
      # save state name as object to use later
      stateName <- substr(basename(tiledir), start=1, stop=7)
    } else {
      # save state name as object to use later
      stateName <- substr(basename(tiledir), start=1, stop=2)
    }
    
      logger::log_info(paste0('Starting clip for ', stateName))
      
    # filter shapefile to one state
    this_state <- dplyr::filter(regionalextent, STUSPS == stateName)

    for (i in 1:length(files_toread)) {
    
        fname <- gsub(basename(files_toread[[i]]), pattern="_FinalRasterCompress", replacement = "")
        outpath <- paste0(intermediate_dir, '/StateRasters/', CDLYear, "/", fname)
        
        # create output directory if it doesn't already exist
        if (!dir.exists(paste0(intermediate_dir, '/StateRasters/', CDLYear))) {
            dir.create(paste0(intermediate_dir, '/StateRasters/', CDLYear), recursive=T)
        }
        
        state <- terra::rast(files_toread[[i]])
        
        if (!'SpatVector' %in% class(this_state)) {
        this_state <- sf::st_transform(this_state, crs=terra::crs(state)) %>% 
            terra::vect()
        }
        
        if (compress == T) {
        state_clipped <- terra::crop(state, this_state) %>%
            terra::mask(this_state, filename=outpath, wopt= list(gdal=c("COMPRESS=DEFLATE", "PREDICTOR=3")), overwrite=T)
        
        } else {
            state_clipped <- terra::crop(state, this_state) %>%
            terra::mask(this_state, filename=outpath, overwrite=T)
        }
        
    }
  }
}
    
    
    
    
    