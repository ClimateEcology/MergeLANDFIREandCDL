library(dplyr)
library(RSQLite)
library(DBI)
library(readr)

for (year in as.character(c(2012:2021))) {
  #regions <- c('WestN', 'WestS', 'Southeast', 'Northeast')
  regions <- c('WestS') 

  for (regionName in regions) {
    tictoc::tic()
    logger::log_info(year, ": Starting ", regionName, ".")

    if (regionName %in% c('WestN')) {
      states <- c('MT', 'WY', 'OR', 'WA', 'ID')
    } else if (regionName %in% c('WestS')) {
      states <- c('CA', 'NV', 'UT', 'CO', 'AZ', 'NM')
    } else {
      
      # load shapefile for state/region 
      regionalextent <- sf::st_read(paste0('./data/SpatialData/', regionName , '.shp'))
      states <- regionalextent$STUSPS
      
      if(regionName == 'Southeast') {
        states <- c(states, "TX")
      }
    }
    
    # save names before creating (database and table within the database)
    db_name <- "./data/mismatchedpixels.sqlite"
    table_name <- "mismatch_bycell"
    
    geo_path <- paste0('./data/TechnicalValidation/Mismatch_spatial/MismatchedPixels_', regionName, '_CDL', year,'_NVC2016.gpkg')
    
    
    db <- dbConnect(SQLite(), dbname = db_name)
    
    # convert csv to sqlite
    
    # read_csv_chunked(pth_to_raw, 
    #                  callback = function(chunk, dummy){
    #                    dbWriteTable(db, table_name, chunk, append = T)}, 
    #                  chunk_size = 100000, col_types = "ciiffffdfff",
    #                  progress=T,
    #                  col_names = c("Empty","x","y","NVC_Class","CDL_Class",
    #                                "CDLYear","State","ncells_tile","STATE2","COUNTY","FIPS"),
    #                  skip=1)
    
    
    # data <-  dbGetQuery(conn = db,
    #                     paste0("SELECT x, y, NVC_Class, CDL_Class, CDLYear, STATE,
    #                            COUNTY, FIPS FROM mismatch_bycell WHERE CDLYear = ", year))

    
    ## OR
    
    mismatch_oneyear <- tbl(db, table_name)
    
    # to decrease file size, remove unnecessary attributes 
    # and filter down to one year and group of states
    tictoc::tic()
    data <- mismatch_oneyear  %>% 
      select(-Empty, -ncells_tile, -STATE2, -COUNTY) %>% 
      filter(CDLYear == year & State %in% states) %>%
      collect()
    tictoc::toc()
    
    # convert to spatial vector object
    data_sp <- data %>%
      filter(!is.na(x) & !is.na(y)) %>%
      sf::st_as_sf(coords=c("x", "y"))
    
    # define crs for spatial points
    sf::st_crs(data_sp) <- 5070

    if (!dir.exists('./data/TechnicalValidation/Mismatch_spatial')) {
      dir.create('./data/TechnicalValidation/Mismatch_spatial')
    }
    
    data_sp %>% sf::st_write(geo_path, 
                             layer_options = "SPATIAL_INDEX=NO",
                             delete_layer = T)
    tictoc::toc()
  }
}