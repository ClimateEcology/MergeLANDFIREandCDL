#!/bin/bash

tiles=TRUE
merge=TRUE
allstates=FALSE

year=2016
sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast',\
mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_large_states.sbatch
sleep 1s

year=2017
sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast',\
mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_large_states.sbatch
sleep 1s

year=2018
sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast',\
mktiles=$tiles,runmerge=$merge,allstates=$allstates RunMerge_large_states.sbatch
sleep 1s