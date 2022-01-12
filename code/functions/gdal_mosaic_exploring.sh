# build virtual mosaic w/ gdal, then convert to output file
# this seems to be the same steps used by R package gdalUtilities::mosaic_rasters
# is it faster to use gdal directly rather than R wrapper?

# to do: figure out how to generate list of files to mosaic in bash
gdalbuildvrt mosaic.vrt c:\data\....\*.tif
gdal_translate -of GTiff -co "COMPRESS=JPEG" -co "PHOTOMETRIC=YCBCR" -co "TILED=YES" mosaic.vrt mosaic.tif