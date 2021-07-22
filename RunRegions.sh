#!/bin/bash

year=2016
sbatch --job-name=MergeSoutheast --export=ALL, cdlyear=$year, region='Southeast' RunMergeLANDFIREandCDL_byState.sbatch
sbatch --job-name=MergeNortheast --export=ALL, cdlyear=$year, region='Northeast' RunMergeLANDFIREandCDL_byState.sbatch
sbatch --job-name=MergeMidwest --export=ALL, cdlyear=$year, region='Midwest' RunMergeLANDFIREandCDL_byState.sbatch
sbatch --job-name=MergeWest --export=ALL, cdlyear=$year, region='West' RunMergeLANDFIREandCDL_byState.sbatch