# get CDL year from sbatch file
args <- commandArgs(trailingOnly = T)
year <- args[2] # year of NASS Cropland Data Layer

library(terra)
library(dplyr)

terraOptions(memfrac=0.9)

tictoc::tic("All regions")
setwd('/project/geoecoservices/MergeLANDFIREandCDL')    
         
# set up names to use for input and & output files
generate_source <- F
movetotemplate <- T


vct_dir <- paste0('./data/TechnicalValidation/Mismatch_spatial/', year)
vct_paths <- list.files(vct_dir, full.names=T)

# create directories for mismatched pixels rasters, if necessary
if (!dir.exists('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/')) {
  dir.create('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/')
}
if (!dir.exists('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/Regional')) {
  dir.create('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/Regional')
}

# file paths for later
infile <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRastersSetNoData/CDL2021NVC_NationalRaster.tif'
empty_template_national <-'/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster.tif'
tmpfile <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/temp', year, '.tif')

if (!file.exists(empty_template_national)) {
  # create national template raster (later, I'll clip this down to individual regions)
  system(paste0("gdal_calc.py -A ", infile, 
                                  " --outfile=", empty_template_national, 
                                  " --calc=", shQuote("0*(A>-2000)"), 
                                  " --NoDataValue=255 --type=Byte")) 
  # change metadata tag to reflect appropriate no data value
  system(paste0('gdal_edit.py ', empty_template_national, ' -a_nodata 255'))
}

regions <- c('Northeast', 'SoutheastW', 'SoutheastE','WestN', 'WestS', 'Midwest')

for (r in regions) {
  n <- 20
  
  # increase number of chunks for large regions
  if (r %in% c('WestN', 'WestS', 'SoutheastW')) {
    n <- 70
  } else if (r %in% c('SoutheastE')) {
    n <- 120
  }
  
  # file paths for later
  empty_template_region <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster_', 
                                  r, '.tif')
  region_boundary <- paste0('/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/', r, '_boundary.shp') 
  
  # if regional templates don't exist, create them by clipping national template
  if (!file.exists(empty_template_region)) {
    
    if(!file.exists(region_boundary)) {
      # Need to handle West separately to divide into north/south. Too big to run entire section.
      if (r %in% c('WestN', 'WestS')) {
        # load shapefile for state/region 
        regionalextent <- sf::st_read(paste0('./data/SpatialData/West.shp'))
      
        if (r == 'WestN') {
          regionalextent <- regionalextent %>%
            dplyr::filter(STUSPS %in% c('MT', 'WY', 'OR', 'WA', 'ID')) %>%    
            sf::st_union() %>%
            sf::st_write(region_boundary)
        } else if (r == 'WestS'){
          regionalextent <- regionalextent %>%
            dplyr::filter(STUSPS %in% c('CA', 'NV', 'UT', 'CO', 'AZ', 'NM')) %>%    
            sf::st_union() %>%
            sf::st_write(region_boundary)
        }
      } else if (r %in% c('SoutheastW', 'SoutheastE')) {
        # load shapefile for state/region 
        regionalextent <- sf::st_read(paste0('./data/SpatialData/Southeast.shp'))
        
        if (r == 'SoutheastE') {
          regionalextent <- regionalextent %>%
            dplyr::filter(STUSPS %in% c('MS', 'TN', 'KY', 'AL', 'GA', 'FL', 'NC', 'SC', 'VA', 'WV', 'MD', 'DE', 'DC')) %>%    
            sf::st_union() %>%
            sf::st_write(region_boundary, append=F)
        } else if (r == 'SoutheastW'){
          regionalextent <- regionalextent %>%
            dplyr::filter(STUSPS %in% c('TX_West', 'TX_East', 'TX', 'OK', 'LA', 'AR')) %>%     # include all variants of TX name
            sf::st_union() %>%
            sf::st_write(region_boundary, append=F)
        }
      } else {
      
      # load shapefile for state/region 
      regionalextent <- sf::st_read(paste0('./data/SpatialData/', r , '.shp')) %>%
        sf::st_union() %>%
        sf::st_write(region_boundary)
      }
    }
    
    # clip national template down to region of interest
    logger::log_info("Creating regional template for ", r, ".")
    system(paste0('gdalwarp -cutline ', region_boundary, " -crop_to_cutline ", 
           empty_template_national, " ", empty_template_region))
    
    # # load cropped raster into R 
    # template_region_rst <- empty_template_region %>%
    #   terra::rast()
    # 
    # # load regional boundary polygon
    # regionalextent <- region_boundary %>% terra::vect()
    # 
    # # mask template polygon by regional boundary
    # template_region_masked <- template_region_rst %>% terra::mask(regionalextent)
    # 
    # # write masked raster (as replacement for crop-only version)
    # template_region_masked %>% terra::writeRaster(empty_template_region)
    
  }
  
  ##### CREATE SOURCE RASTERS 
  # raster version of vector data in small chunks that we will combine later
  
  ##### SAVE FILE NAMES
  vct_paths <- list.files(vct_dir, full.names=T)
  region_vct_path <- vct_paths[grepl(vct_paths, pattern=r)]
  
  bsename <- gsub(basename(region_vct_path), pattern='.gpkg', replacement='')
  
  target_file <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/Regional/', bsename, '.tif')
  target_binary <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/Regional/', bsename, '_binary.tif')
  
  # make series of file names for source rasters (number of names is equal to n, for number of chunks to split for processing)
  out_rst <- paste0(paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/', 
                           bsename, paste0("_", 1:n, '.tif'))) 
  
  if (generate_source == T) {
    
    logger::log_info("Loading raster and vector data for ", r, ".")
      
    ##### LOAD DATA (to avoid doing it inside loop for each chunk)
    # load regional template raster
    template_region_rst <- empty_template_region %>%
      terra::rast()
    
    # read vector data for specified region  
    vct <- region_vct_path %>%
      terra::vect() 
    
  ##### EXECUTE LOOP TO CREATE SOURCE RASTERS FOR CHUNKS OF VECTOR DATA

    for (i in 1:n) {
      logger::log_info("Generating chunk ", i, " for ", r, ".")
      
      # divide into smaller chunks to rasterize
      nrows_chunk <- ceiling(nrow(vct)/n)
      
      logger::log_info(r, " chunk ", i, ": filtering vector data.")
      
      vct_sub <- vct[((nrows_chunk)*(i-1)+1):((nrows_chunk)*(i)),]
      
      # crop raster template to extent of vector chunk
      small_template <- template_region_rst %>%
        terra::crop(vct_sub)
      
      area_bbox <- small_template %>% terra::ext() %>% 
        terra::as.polygons() %>%
        terra::expanse()
      
      if (area_bbox > 1e+12) {
        logger::log_info("This chunk is too big. Split in half using k-means clusters.")
        sub_split <- 2 # how many groups to split into?
        
        # k-means clustering to assign points to groups based on proximity
        xy <- data.frame(geom(vct_sub))
        set.seed(42)
        km <- kmeans(cbind(xy$x, xy$y), centers=sub_split)
        vct_sub$cluster <- km$cluster

        for (h in 1:sub_split) {
          # make file name for extra output raster
          out_name <- paste0(paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/', 
                                   bsename, paste0("_", i, "_", h, '.tif'))) 
          
          # append new name to set of rasters
          out_rst <- c(out_rst, out_name)

          
          logger::log_info(r, " chunk ", i, " pt", h, ": filtering vector data.")
          
          # split vector data based on k-means clustering
          vct_sub2 <- vct_sub %>% 
            sf::st_as_sf() %>%
            dplyr::filter(cluster == h) %>%
            terra::vect()
          
          # crop raster template to extent of vector chunk
          small_template <- template_region_rst %>%
            terra::crop(vct_sub2)
          
          # rasterize grouped vector data
          logger::log_info(r, " chunk ", i, " pt", h, ": rasterizing.")
          mismatch_rst1 <- terra::rasterize(x=vct_sub2, y=small_template, field=1,
                                            background=0, filename=out_name, overwrite=T, 
                                            wopt=list(progress=T, memfrac=0.9, NAflag=255))
        }
      } else {
      
        logger::log_info(r, " chunk ", i, ": rasterizing.")
        mismatch_rst1 <- terra::rasterize(x=vct_sub, y=small_template, field=1,
                             background=0, filename=out_rst[i], overwrite=T, 
                             wopt=list(progress=T, memfrac=0.9, NAflag=255))
      }
    }
    
  }
  
  ##### TRANSFER DATA FROM SOURCE RASTERS TO REGIONAL TEMPLATE
  if (movetotemplate == T) {
    
    # make list of raster chunks to accomodates those split in half in previous step
    out_rst <- list.files('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/', full.names=T)
    # filter raster chunks to appropriate year and region
    out_rst <- out_rst[grepl(out_rst, pattern= paste0('CDL', year)) & grepl(out_rst, pattern=r)] 
    
    for (i in 1:length(out_rst)) {
      logger::log_info("Transferring chunk ", i, " for ", r, ".")
      
      # change no data value for source chunk so expansion below fills with zeros
      system(paste0('gdal_edit.py -unsetnodata ', out_rst[i]))
      system(paste0('gdal_edit.py -a_nodata 0 ', out_rst[i]))
      
      # read template raster (starts as empty raster that we will add data to)
      empty_template <- empty_template_region %>%
        terra::rast()
      
      # save extent of template raster
      template_bounds <- as.numeric(c(ext(empty_template)$xmin,ext(empty_template)$ymin, 
                                      ext(empty_template)$xmax, ext(empty_template)$ymax)) %>%
        paste0(collapse=" ")
      
      # expand source raster to have same spatial extent as template
      system(paste0('gdalwarp -te ', template_bounds, " -overwrite ", out_rst[i],  " ", 
                               tmpfile))
      
      # so raster multiplication works in next step, change no data value (if no data is zero, can't add values in next step)
      system(paste0('gdal_edit.py -unsetnodata ', tmpfile))
      system(paste0('gdal_edit.py -a_nodata 255 ', tmpfile))
      
      # add source data to template
      if (i == 1) { # for the first chunk, we use the empty template raster
        system(paste0("gdal_calc.py -A ", empty_template_region, " -B ", tmpfile, 
                       " --outfile=", target_file, 
                       " --calc=", shQuote("A+B"), " --type=Byte"))
      } else if (i > 1) { # after the first chunk we keep adding data to the target raster
        system(paste0("gdal_calc.py -A ", target_file, " -B ", tmpfile, 
                        " --outfile=", target_file, 
                        " --calc=", shQuote("A+B"), " --type=Byte"))
      }
    }
    
    # some mismatched pixels have values higher than 1 due to duplication in vector data 
    # by tabulating values from tiled rasters, there is overlap between states that duplicates mismatch points
    # rather than filtering out duplicates earlier (takes SO long), here, I reset count of mismatched pixels to one
    
    system(paste0("gdal_calc.py -A ", target_file, 
                  " --outfile=", target_binary, 
                  " --calc=", shQuote("A>0"), " --type=Byte"))
  }
  # close loop for regions
}

tictoc::toc()