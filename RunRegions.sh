#!/bin/bash

year=2016
tiles=FALSE
merge=FALSE
sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch
#sbatch --job-name=MergeNortheast --export=ALL,cdlyear=$year,region='Northeast',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch
#sbatch --job-name=MergeMidwest --export=ALL,cdlyear=$year,region='Midwest',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch
#sbatch --job-name=MergeWest --export=ALL,cdlyear=$year,region='West',mktiles=$tiles,runmerge=$merge RunMerge_in_container_bigmem_bystate.sbatch