#!/bin/bash

year=2016
sbatch --job-name=MergeSoutheast --export=ALL,cdlyear=$year,region='Southeast' RunMerge_in_container_bigmem_bystate.sbatch
sbatch --job-name=MergeNortheast --export=ALL,cdlyear=$year,region='Northeast' RunMerge_in_container_bigmem_bystate.sbatch
sbatch --job-name=MergeMidwest --export=ALL,cdlyear=$year,region='Midwest' RunMerge_in_container_bigmem_bystate.sbatch
sbatch --job-name=MergeWest --export=ALL,cdlyear=$year,region='West' RunMerge_in_container_bigmem_bystate.sbatch