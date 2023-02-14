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

regions <- c('Midwest', 'West', 'Northeast', 'Southeast')

#for (r in regions) {
  r <- regions[1]  
  region_vct_path <- vct_paths[grepl(vct_paths, pattern=r)]
  
  bsename <- gsub(basename(region_vct_path), pattern='.gpkg', replacement='')
  
  # make series of file names for output rasters (number of names is equal to n, for number of chunks to split for processing)
  out_rst <- paste0(paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/', 
                           bsename, paste0("_", 1:n, '.tif'))) 

  for (i in 1:n) {
    logger::log_info("Starting chunk ", i, " for ", r, ".")
  
    vct <- region_vct_path %>%
      terra::vect()
    
    nrows_chunk <- nrow(vct)/n
    
    tictoc::tic()
    vct_sub <- vct[((nrows_chunk)*(i-1)+1):((nrows_chunk)*(i)),]
    tictoc::toc()

    # remove large vector object to free memory
    rm(vct)
    
    small_template <- rst_template %>%
      terra::crop(vct_sub)
    
    mismatch_rst1 <- terra::rasterize(x=vct_sub, y=small_template, field=1,
                         background=0, filename=out_rst[i], overwrite=T, 
                         wopt=list(progress=T, memfrac=0.9, NAflag=NA))
    rm(small_template)
    rm(mismatch_rst1)
  }
  
#}



# make template raster to receive mismatched pixel values 
# change all values to in one merged raster to be all zeros
# then we can fill in ones to indicate mismatched pixels, where necessary
  
# file paths to write later
infile <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRastersSetNoData/CDL2021NVC_NationalRaster.tif'
empty_template_file <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster.tif'
tmpfile <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/temp.tif'
target_file <- paste0('/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/',
                      bsename, '.tif')
empty_template_nodata <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/EmptyTemplateRaster_ZeroAsNoData.tif'

# Create national templates to receive mismatched pixel information
# one copy that defines zero as the no data value and one that does not

# create template WITH no data value
cleartemplate_command <- paste0("gdal_calc.py -A ", infile, 
                                " --outfile=", empty_template_nodata, 
                       " --calc=", shQuote("0*(A>-2000)"), 
                       " --NoDataValue=0 --type=Byte") 

system(cleartemplate_command) # execute gdal command

# create template WITHOUT no data value
system(paste0('cp ', empty_template_nodata, " ", empty_template_file))
system(paste0('gdal_edit.py -unsetnodata ', empty_template_file))

 
# read target raster (starts as empty raster that we will add data to)
empty_template <- empty_template_nodata %>%
  terra::rast()

# save extent of target raster
template_bounds <- as.numeric(c(ext(empty_template)$xmin,ext(empty_template)$ymin, 
                     ext(empty_template)$xmax, ext(empty_template)$ymax)) %>%
  paste0(collapse=" ")


# expand source raster to have same spatial extent as target
expand_command <- paste0('gdalwarp -te ', template_bounds, " -overwrite ", out_rst[1],  " ", 
       tmpfile)
system(expand_command)

# add together target data and source data
calc_command <- paste0("gdal_calc.py -A ", empty_template_file, " -B ", tmpfile, 
                       " --outfile=", target_file, 
                       " --calc=", shQuote("A+B"), " --type=Byte") 
system(calc_command)
