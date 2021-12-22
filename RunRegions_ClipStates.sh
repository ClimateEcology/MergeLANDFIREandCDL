#!/bin/bash

clipstates=TRUE
allstates=TRUE

#year=2020
for year in 2012 2016 2017 2018 2019 2020
do
sbatch --job-name=ClipSoutheast --export=ALL,cdlyear=$year,region='Southeast',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name=ClipNortheast --export=ALL,cdlyear=$year,region='Northeast',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name=ClipMidwest --export=ALL,cdlyear=$year,region='Midwest',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name=ClipWest --export=ALL,cdlyear=$year,region='West',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
done
