#!/bin/bash

clipstates=TRUE
allstates=TRUE

year=2020
sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name=MergeNortheast --export=ALL,cdlyear=$year,region='Northeast',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name=MergeMidwest --export=ALL,cdlyear=$year,region='Midwest',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch
sleep 1s

sbatch --job-name=MergeWest --export=ALL,cdlyear=$year,region='West',\
clipstates=$clipstates,allstates=$allstates ClipStateRaster_bigmem.sbatch