
season <- NA
ID <- 'CDL2020NVC'
tiledir <- 'D:/MergeLANDFIRECDL_Rasters/TX_WestTiles_414/MergedCDLNVC'
chunksize1 <- 20
chunksize2 <- 4

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


tile_list <- vector("list", length(tile_paths))

for (i in 1:length(tile_paths)) {
  tile_list[[i]] <- terra::rast(tile_paths[i])
}

end <- length(tile_list)  



# execute mosaic commands respecting group membership

for (i in 1:ngroups) {
  
  assign(x=paste0('args', i), value=tile_list[clusters == i]) 
  
}

# for the list of chunksize1 or fewer tiles, execute mosaic to create a mega-tile
assign(x=paste0('MT', i), value= base::eval(rlang::call2("mosaic", !!!get(paste0('args', i)), .ns="terra", fun='mean',
                                                         filename=paste0(tiledir, '/', ID,"_MegaTile", i, '.tif'), overwrite=T)))









