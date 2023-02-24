
for (CDLYear in c(2012:2015)) {
  logger::log_info('Starting ', CDLYear)
  # save necessary file paths and parameters
  regional_dir <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/Regional/'
  outdir <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/MismatchedPixelRasters/National/'
  ID <- 'MismatchedPixels'
  season <- paste0('CDL', CDLYear, "_NVC2016_binary")
    
  # if necessary, create output directories
  if (!dir.exists(outdir)) {
    dir.create(outdir)
  }
  
  # take out megatile(s) from previous mosaic attempt
  regional_files <- list.files(regional_dir, full.names=T)
  to_remove <- regional_files[grepl(regional_files, pattern='NationalMegaTile')]
  file.remove(to_remove)
  
  
  logger::log_info(CDLYear, ": joining regions into one national raster of mismatched pixels.")
  
  # mosaic regions to national raster
  beecoSp::mosaic_states(statedir=regional_dir,
                         outdir=outdir, 
                         tier=3, 
                         ID=ID, 
                         season=season,
                         usepackage='gdal')

}