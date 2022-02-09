#!/bin/bash

jobids="" # declare empty string for all job ids (converting data type)
years=(2013) # which years to run

########## Part 1: convert data type to Int16 for final, national rasters
# run this section first, only start other jobs when these are complete

for year in "${years[@]}"
do
    convert_id=$(sbatch --job-name="ConvertDT$year" --export=ALL,cdlyear=$year ConvertDatatype.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$convert_id"
done
jobids="${jobids:1}" # strip off leading comma

########## Part 2: Test that output rasters look good
# this sections runs checks on crs, extent, file size, and raster values
year=all

sbatch --dependency=afterany:${jobids} --job-name="Tests$year" --export=ALL,cdlyear="$year" RunTests.sbatch
sleep 1s

########## Part 3: Tabulate the number of pixels in NVC, CDL, and merged raster layers
# for year in "${years[@]}"
# do
#     sbatch --dependency=afterany:${jobids} --job-name="TabPixels$year" --export=ALL,cdlyear="$year" TabPixels.sbatch
#     sleep 1s
# done