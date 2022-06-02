#!/bin/bash

jobids="" # declare empty string for all job ids (converting data type)

years=(2021 2020 2019 2018 2017 2016 2015 2014 2013 2012)


########## Part 3.1: convert data type to Int16 for final, national rasters
# run this section first, only start other jobs when these are complete

for year in "${years[@]}"
do
    convert_id=$(sbatch --job-name="ConvertDatatype$year" --export=ALL,cdlyear=$year 03_1ConvertDatatype.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$convert_id"

done
jobids="${jobids:1}" # strip off leading comma

########## Part 2: Tabulate the number of pixels in NVC, CDL, and merged raster layers
for year in "${years[@]}"
do
    sbatch --dependency=afterany:${jobids} --job-name="TabPixels$year" --export=ALL,cdlyear="$year" 03_2TabPixels.sbatch
    sleep 1s
done

########## Part 3: Test that output rasters look good
# this section runs checks on crs, extent, file size, and raster values for state-level maps
year=all # implementation of file size checks mean that it makes the most sense to examine all years at the same time

sbatch --job-name="Tests$year" --export=ALL,cdlyear="$year" 03_3RunTests.sbatch
sleep 1s
