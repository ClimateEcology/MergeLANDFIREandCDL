#!/bin/bash

clipstates=TRUE
allstates=TRUE

for year in 2013 2014 2015
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
