#!/bin/bash

# download all years of CDL
cd /project/geoecoservices
mkdir CroplandDataLayer
cd /CroplandDataLayer

years=($(seq 2008 2010))

# loop through necessary years
for year in "${years[@]}"
do

curl https://www.nass.usda.gov/Research_and_Science/Cropland/Release/datasets/${year}_30m_cdls.zip -o ./${year}_30m_cdls.zip
unzip ${year}_30m_cdls.zip

done

# define raster NoData values (translate from NA to zero)
# helpful stackoverflow discussion: https://gis.stackexchange.com/questions/134084/replacing-nan-pixel-values-in-geotiff-using-gdal

module load gdal # update this if GDAL Python bindings are a separate module

# identify which CDL years have different (or are lacking) no data values
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2020_30m_cdls.tif # need to convert
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2021_30m_cdls.tif # need to convert
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2008_30m_cdls.tif # need to convert
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2009_30m_cdls.tif # need to convert
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2010_30m_cdls.tif # need to convert
gdalinfo /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/2011_30m_cdls.tif # need to convert

# change no data value to zero (instead of NA). NA as no data value messes up spatial workflows in some cases
module load singularity

container='/project/geoecoservices/Containers/geospatial_extend_v1.57.sif'

# this array is only specific years that we need to change no data values
years=(2008 2009 2010 2011 2012 2016 2017 2019 2020 2021)

# loop through necessary years
for year in "${years[@]}"
do

singularity exec $container gdal_calc.py -A /project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/${year}_30m_cdls.tif --outfile=/project/geoecoservices/MergeLANDFIREandCDL/data/SpatialData/CDL/${year}_30m_cdls_fixNA.tif --calc="A" --type=Byte --NoDataValue=0 -co COMPRESS=DEFLATE -co BIGTIFF=YES

done
