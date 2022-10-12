# convert national rasters to Int16 data type (terra output is Float32)

# get CDL year from sbatch file
args <- commandArgs(trailingOnly = T)
CDLYear <- args[2] # year of NASS Cropland Data Layer
    
# save directory paths
dir_path <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRasters'
temprst_dir <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRastersTemp'
outrst_dir <- '/90daydata/geoecoservices/MergeLANDFIREandCDL/NationalRastersSetNoData'


files <- list.files(dir_path, full.names = T)
files <- files[!grepl(files, pattern= ".tif.aux")]
files <- files[grepl(files, pattern= CDLYear)]


if (!dir.exists(outrst_dir)) {
  dir.create(outrst_dir)
}

if (!dir.exists(temprst_dir)) {
  dir.create(temprst_dir)
}

outrst_name <- basename(files)

logger::log_info('Starting gdal_calc for ', CDLYear, '.')

# translate raster to integer value (multiply all values by 1000)
calc_command <- paste0("gdal_calc.py -A ", files, " --outfile=", paste0(temprst_dir, "/", outrst_name), 
                       " --calc=", shQuote("-9999*(A==0)+A"), " --NoDataValue=-9999") # save gdal command

for (i in 1:length(calc_command)) {
  system(calc_command[i]) # execute gdal command
  logger::log_info('gdal_calc: completed ', outrst_name[i])
}

logger::log_info('Created temporary rasters for', CDLYear, ' (original raster with no data set to -9999).')

tmp_files <- list.files(temprst_dir, full.names = T)
tmp_files <- files[!grepl(tmp_files, pattern= ".tif.aux")]
tmp_files <- files[grepl(tmp_files, pattern= CDLYear)]

# move raster to national rasters file and convert to signed Int16 instead of float32
gdalUtils::gdal_translate(src_dataset=tmp_files, dst_dataset = paste0(outrst_dir, "/", outrst_name),
                          ot='Int16', co=c("COMPRESS=DEFLATE", "BIGTIFF=YES"), verbose=T)

logger::log_info('Finished converting ', CDLYear, ' output raster to Int16.')