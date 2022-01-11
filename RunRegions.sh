#!/bin/bash

tiles=TRUE
merge=TRUE
allstates=TRUE

#for year in 2012 2013 2014 2015 2016 2017 2018 2019 2020
for year in 2014

do
#sbatch --job-name="SouthE$year" --export=ALL,cdlyear=$year,region='Southeast',\
#mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_in_container_bigmem_bystate.sbatch
#sleep 1s

#sbatch --job-name="NorthE$year" --export=ALL,cdlyear=$year,region='Northeast',\
#mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_in_container_bigmem_bystate.sbatch
#sleep 1s

#sbatch --job-name="MidW$year" --export=ALL,cdlyear=$year,region='Midwest',\
#mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_in_container_bigmem_bystate.sbatch
#sleep 1s

sbatch --job-name="West$year" --export=ALL,cdlyear=$year,region='West',\
mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_in_container_bigmem_bystate.sbatch
sleep 1s

done
