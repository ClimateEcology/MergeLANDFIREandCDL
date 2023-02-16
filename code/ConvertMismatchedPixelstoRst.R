library(terra)
library(dplyr)

terraOptions(memfrac=0.9)

setwd('/project/geoecoservices/MergeLANDFIREandCDL')    
         
# set up names to use for input and & output files
year <- 2021
n <- 20

rst_template <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRastersSetNoData/CDL2021NVC_NationalRaster.tif' %>%
  terra::rast()

vct_dir <- paste0('./data/TechnicalValidation/Mismatch_spatial/', year)
vct_paths <- list.files(vct_dir, full.names=T)

# create directory for mismatched pixels rasters, if necessary
if (!dir.exists('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/')) {
  dir.create('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/')
}


# file paths for later
infile <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRastersSetNoData/CDL2021NVC_NationalRaster.tif'
empty_template_national <-'/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster.tif'
tmpfile <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/temp.tif'
target_file <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/MismatchedPixels_',
                      r, '_CDL2021_NVC2016.tif')

if (!file.exists(empty_template_national)) {
  # create national template raster (later, I'll clip this down to individual regions)
  system(paste0("gdal_calc.py -A ", infile, 
                                  " --outfile=", empty_template_national, 
                                  " --calc=", shQuote("0*(A>-2000)"), 
                                  " --NoDataValue=255 --type=Byte")) 
}

#regions <- c('West', 'Southeast', Midwest', 'Northeast')
regions <- c('West', 'Southeast', 'Northeast')


for (r in regions) {
  
  # increase number of chunks for large regions
  if (r %in% c('West', 'Southeast')) {
    n <- 40
  }
  # file paths for later
  empty_template_region <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster_', 
                                  r, '.tif')
  region_boundary <- paste0('/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/', r, '_boundary.shp')
  
  # if regional templates don't exist, create them by clipping national template
  if (!file.exists(empty_template_region)) {
    # load shapefile for state/region 
    regionalextent <- sf::st_read(paste0('./data/SpatialData/', r , '.shp')) %>%
      sf::st_union() %>%
      sf::st_write(region_boundary)
    
    # clip national template down to region of interest
    logger::log_info("Creating regional template for ", r, ".")
    system(paste0('gdalwarp -cutline ', region_boundary, " -crop_to_cutline ", 
           empty_template_national, " ", empty_template_region))
  }
  
  ##### CREATE SOURCE RASTERS 
  # raster version of vector data in small chunks that we will combine later
  
  region_vct_path <- vct_paths[grepl(vct_paths, pattern=r)]
  
  bsename <- gsub(basename(region_vct_path), pattern='.gpkg', replacement='')
  
  target_file <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/', bsename, '.tif')
  
  # make series of file names for source rasters (number of names is equal to n, for number of chunks to split for processing)
  out_rst <- paste0(paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/', 
                           bsename, paste0("_", 1:n, '.tif'))) 

  for (i in 1:n) {
    logger::log_info("Generating chunk ", i, " for ", r, ".")
  
    # read vector data for specified region  
    vct <- region_vct_path %>%
      terra::vect()
    
    # divide into smaller chunks to rasterize
    nrows_chunk <- nrow(vct)/n
    
    logger::log_info(r, "chunk ", i, ": filtering vector data.")
    vct_sub <- vct[((nrows_chunk)*(i-1)+1):((nrows_chunk)*(i)),]

    # remove large vector object to free memory
    rm(vct)
    
    # crop raster template for entire county to extent of vector chunk
    small_template <- rst_template %>%
      terra::crop(vct_sub)
    
    logger::log_info(r, "chunk ", i, ": rasterizing.")
    mismatch_rst1 <- terra::rasterize(x=vct_sub, y=small_template, field=1,
                         background=0, filename=out_rst[i], overwrite=T, 
                         wopt=list(progress=T, memfrac=0.9, NAflag=NA))
    rm(small_template)
    rm(mismatch_rst1)

  }
  
  for (i in 1:n) {
    logger::log_info("Transferring chunk ", i, " for ", r, ".")
    
    ##### Transfer values from source raster to template!
  
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
    system(paste0('gdalwarp -te ', template_bounds, " -overwrite ", out_rst[1],  " ", 
                             tmpfile))
    
    # add source data to template
    system(paste0("gdal_calc.py -A ", empty_template_region, " -B ", tmpfile, 
                           " --outfile=", target_file, 
                           " --calc=", shQuote("A+B"), " --type=Byte"))
  }
}
  

  
  
  
  
  
  
  
  
  
  
  
  
  

# make template raster to receive mismatched pixel values 
# change all values to in one merged raster to be all zeros
# then we can fill in ones to indicate mismatched pixels, where necessary
  
# file paths for later

target_file <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/',
                      bsename, '.tif')
empty_template_nodata <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster_ZeroAsNoData.tif'

# Create national templates to receive mismatched pixel information
# one copy that defines zero as the no data value and one that does not

# create template WITH no data value
cleartemplate_command <- paste0("gdal_calc.py -A ", infile, 
                                " --outfile=", empty_template_region, 
                       " --calc=", shQuote("0*(A>-2000)"), 
                       " --NoDataValue=255 --type=Byte") 

system(cleartemplate_command) # execute gdal command

# create template WITHOUT no data value
system(paste0('cp ', empty_template_nodata, " ", empty_template_file))
system(paste0('gdal_edit.py -unsetnodata ', empty_template_file))


# change no data value for source chunk so expansion below fills with zeros
system(paste0('gdal_edit.py -unsetnodata ', out_rst[1]))
system(paste0('gdal_edit.py -a_nodata 0 ', out_rst[1]))

# read target raster (starts as empty raster that we will add data to)
empty_template <- empty_template_region %>%
  terra::rast()

# save extent of target raster
template_bounds <- as.numeric(c(ext(empty_template)$xmin,ext(empty_template)$ymin, 
                     ext(empty_template)$xmax, ext(empty_template)$ymax)) %>%
  paste0(collapse=" ")

# expand source raster to have same spatial extent as target
expand_command <- paste0('gdalwarp -te ', template_bounds, " -overwrite ", out_rst[1],  " ", 
       tmpfile)
system(expand_command)

system(paste0('gdalinfo ', tmpfile))
system(paste0('du -sh ', tmpfile))
system(paste0('gdalinfo ', empty_template_region))
system(paste0('du -sh ', empty_template_sm))



# add together target data and source data
calc_command <- paste0("gdal_calc.py -A ", empty_template_sm, " -B ", tmpfile, 
                       " --outfile=", target_file, 
                       " --calc=", shQuote("A+B"), " --type=Byte") 
system(calc_command)
