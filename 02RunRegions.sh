#!/bin/bash

########## Part 2.1: Generate merged rasters
# parameters for generating rasters
tiles=TRUE
merge=TRUE
mosaic=TRUE
allstates=TRUE
jobids="" # declare empty string for all job ids (generate rasters)

years=(2021 2020 2019 2018 2017 2016 2015 2014 2013 2012)


for year in "${years[@]}"
do
    seid=$(sbatch --job-name="SouthE$year" --export=ALL,cdlyear=$year,region='Southeast',mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates 02_1RunMerge_in_container_bigmem_bystate.sbatch | cut -d ' ' -f4)
    sleep 1s

    neid=$(sbatch --job-name="NorthE$year" --export=ALL,cdlyear=$year,region='Northeast',mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates 02_1RunMerge_in_container_bigmem_bystate.sbatch | cut -d ' ' -f4)
    sleep 1s

    mwid=$(sbatch --job-name="MidW$year" --export=ALL,cdlyear=$year,region='Midwest',mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates 02_1RunMerge_in_container_bigmem_bystate.sbatch | cut -d ' ' -f4)
    sleep 1s

    wid=$(sbatch --job-name="West$year" --export=ALL,cdlyear=$year,region='West',mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates 02_1RunMerge_in_container_bigmem_bystate.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$seid,$neid,$mwid,$wid"
done
jobids="${jobids:1}" # strip off leading comma


########## Part 2.2: Technical Validation
# after all regions and years are finished (generating rasters), compile technical validation data
sbatch --dependency=afterany:${jobids} --export=ALL,parallel=TRUE,nprocess=all 02_2TechnicalValidation.sbatch 

########## Part 2.3: Clip state rasters
# parameters for generating rasters
clipstates=TRUE
clipids="" # declare empty string for all job ids (clip)

for year in "${years[@]}"

do
    seid2=$(sbatch --dependency=afterany:${jobids} --job-name="ClipSE$year" --export=ALL,cdlyear=$year,region='Southeast',clipstates=$clipstates,allstates=$allstates 02_3ClipStateRaster_bigmem.sbatch | cut -d ' ' -f4)
    sleep 1s

    neid2=$(sbatch --dependency=afterany:${jobids} --job-name="ClipNE$year" --export=ALL,cdlyear=$year,region='Northeast',clipstates=$clipstates,allstates=$allstates 02_3ClipStateRaster_bigmem.sbatch | cut -d ' ' -f4)
    sleep 1s

    mwid2=$(sbatch --dependency=afterany:${jobids} --job-name="ClipMW$year" --export=ALL,cdlyear=$year,region='Midwest',clipstates=$clipstates,allstates=$allstates 02_3ClipStateRaster_bigmem.sbatch | cut -d ' ' -f4)
    sleep 1s

    wid2=$(sbatch --dependency=afterany:${jobids} --job-name="ClipWest$year" --export=ALL,cdlyear=$year,region='West',clipstates=$clipstates,allstates=$allstates 02_3ClipStateRaster_bigmem.sbatch | cut -d ' ' -f4)
    
    clipids="$clipids,$seid2,$neid2,$mwid2,$wid2"
done
clipids="${clipids:1}" # strip off leading comma


########## Part 2.4: Mosaic clipped rasters to national maps
# parameters for mosaic operation
tier='1:2:3' # tiers indicate level of hierarchical framework to process (tier 1 is smallest extent, tier 3 is biggest, national map)

for year in "${years[@]}"

do
    sbatch --dependency=afterany:${clipids} --job-name="Mosaic$year" --export=ALL,cdlyear="$year",tier="$tier" 02_4MosaicToNational.sbatch
    sleep 1s
done
