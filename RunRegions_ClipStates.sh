#!/bin/bash

clipstates=TRUE
allstates=TRUE

for year in 2012 2013 2014 2015 2016 2017 2018 2019 2020
#for year in 2020
do

sbatch --job-name="ClipSE$year" --export=ALL,cdlyear=$year,region='Southeast',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name="ClipNE$year" --export=ALL,cdlyear=$year,region='Northeast',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name="ClipMW$year" --export=ALL,cdlyear=$year,region='Midwest',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name="ClipWest$year" --export=ALL,cdlyear=$year,region='West',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
done
