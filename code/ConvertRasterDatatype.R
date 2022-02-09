# convert national rasters to Int16 data type (terra output is Float32)

source('./code/functions/tests/check_rastervalues.R')

# run all years of CDL
for (CDLYear in 2012:2020) {
    
  dir_path <- paste0('../../../90daydata/geoecoservices/MergeLANDFIREandCDL/StateRasters/', CDLYear) 
  outrst_dir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRasters'
  
  # local laptop file paths
  # dir_path <- 'D:/MergeLANDFIRECDL_Rasters/'
  # outrst_dir <- 'D:/MergeLANDFIRECDL_Rasters/NationalRasters'
  
  
  files <- list.files(dir_path, full.names = T)
  files <- files[!grepl(files, pattern= ".tif.aux")]
  files <- files[grepl(files, pattern= "Tier3.tif")]
  files <- files[grepl(files, pattern= CDLYear)]
  
  
  if (!dir.exists(outrst_dir)) {
    dir.create(outrst_dir)
  }
  
  outrst_name <- gsub(basename(files), pattern='_Tier3', replacement="")
  
  # move raster to national rasters file and convert to signed Int16 instead of float32
  gdalUtils::gdal_translate(src_dataset=files, dst_dataset = paste0(outrst_dir, "/", outrst_name),
                            ot='Int16', co=c("COMPRESS=DEFLATE", "BIGTIFF=YES"), verbose=T)
  
  # check that all values in converted rasters are in acceptable range (in attribute table)
  res <- check_rastervalues(CDLYear = i, dir=outrst_dir)
}