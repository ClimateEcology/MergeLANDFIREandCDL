#!/bin/bash

# download necessary spatial data
module load singularity
singularity exec --bind /90daydata:/90daydata geospatial_extend_latest.sif Rscript code/DownloadFormatSpatialData_wInternet.R


# define raster NoData values (translate from NA to zero)
# helpful stackoverflow discussion: https://gis.stackexchange.com/questions/134084/replacing-nan-pixel-values-in-geotiff-using-gdal

module load gdal # update this if GDAL Python bindings are a separate module

# identify which CDL years have different (or are lacking) no data values
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2019_30m_cdls.img

# change no data value to zero (instead of NA). NA as no data value messes up spatial workflow

# file paths for Atlas HPC (pending gdal_calc program being approved for Atlas)
gdal_calc -A /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2019_30m_cdls.img --outfile=/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2019_30m_cdls_fixNA.img --calc="A" --NoDataValue=0
gdal_calc -A /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2017_30m_cdls.img --outfile=/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2017_30m_cdls_fixNA.img --calc="A" --NoDataValue=0
gdal_calc -A /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2016_30m_cdls.img --outfile=/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2016_30m_cdls_fixNA.img --calc="A" --NoDataValue=0
gdal_calc -A /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2012_30m_cdls.img --outfile=/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2012_30m_cdls_fixNA.img --calc="A" --NoDataValue=0


