#!/bin/bash

tiles=TRUE
merge=TRUE
allstates=TRUE

year=2013
sbatch --job-name=NE2013 --export=ALL,cdlyear=$year,region='Northeast',\
mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_in_container_bigmem_bystate.sbatch
sleep 1s

year=2014
sbatch --job-name=NE2014 --export=ALL,cdlyear=$year,region='Northeast',\
mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_in_container_bigmem_bystate.sbatch
sleep 1s
