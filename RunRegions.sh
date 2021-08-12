#!/bin/bash

year=2017
tiles=TRUE
merge=TRUE
#sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch
sleep 1s
sbatch --job-name=MergeNortheast --export=ALL,cdlyear=$year,region='Northeast',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch
sleep 1s
#sbatch --job-name=MergeMidwest --export=ALL,cdlyear=$year,region='Midwest',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch
sleep 1s
#sbatch --job-name=MergeWest --export=ALL,cdlyear=$year,region='West',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch