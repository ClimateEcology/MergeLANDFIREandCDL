#!/bin/bash

#years=(2021 2020 2019 2018 2017 2016 2015 2014 2013 2012)
years=(2021 2020 2019 2018 2017 2016 2015 2014 2013)
container='/project/geoecoservices/Containers/geospatial_extend_v1.56.sif'

jobids="" # declare empty string for all job ids (converting data type)

########## Part 3.11: convert data type to Int16 for final, national rasters
# run this section first, only start other jobs when these are complete

for year in "${years[@]}"
do
    convert_id=$(sbatch --job-name="ConvertNoData$year" --export=ALL,cdlyear=$year,container=$container 03_11ConvertDatatypeNoData.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$convert_id"

done
jobids="${jobids:1}" # strip off leading comma
