# # get CDL year from sbatch file
args <- commandArgs(trailingOnly = T)
CDLYear <- args[2] # year of NASS Cropland Data Layer

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

# # for national raster, convert to compressed format to reduce file size
# 
# tmp_files <- list.files(outdir, full.names = T)
# tmp_files <- tmp_files [!grepl(tmp_files, pattern= ".tif.aux")]
# tmp_files <- tmp_files [grepl(tmp_files, pattern= CDLYear)]
# 
# # move raster to national rasters file and compress
# gdalUtils::gdal_translate(src_dataset=tmp_files, dst_dataset = outdir_compress,
#                           ot='Byte', co=c("COMPRESS=DEFLATE", "BIGTIFF=YES"), verbose=T)
# 
# logger::log_info('Finished converting ', CDLYear, ' to compressed format.')

