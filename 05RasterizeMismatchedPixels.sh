#!/bin/bash

#years=(2021 2020 2019 2018 2017 2016 2015 2014 2013 2012)
years=(2019 2018 2017 2016 2015 2014 2013 2012)
container='/project/geoecoservices/Containers/geospatial_extend_v1.58.sif'

jobids="" # declare empty string for all job ids (converting data type)

# loop through years to generate regional rasters of mismatched pixels
for year in "${years[@]}"
do
    convert_id=$(sbatch --job-name="MismatchedPixels$year" --export=ALL,cdlyear=$year,container=$container 05_RasterizeMismatchedPixels.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$convert_id"

done
jobids="${jobids:1}" # strip off leading comma
