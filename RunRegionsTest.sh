#!/bin/bash

tiles=TRUE
merge=TRUE
mosaic=TRUE
allstates=TRUE

# declare empty string for all job ids
jobids=""

for year in 2020 2019 2018 2017 2016 2015 2014 2013 2012

do
    seid=$(sbatch --job-name="SouthE$year" --export=ALL,cdlyear=$year,region='Southeast',\
    mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    neid=$(sbatch --job-name="NorthE$year" --export=ALL,cdlyear=$year,region='Northeast',\
    mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    mwid=$(sbatch --job-name="MidW$year" --export=ALL,cdlyear=$year,region='Midwest',\
    mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    wid=$(sbatch --job-name="West$year" --export=ALL,cdlyear=$year,region='West',\
    mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$seid,$neid,$mwid,$wid"
done

jobids="${jobids:1}" # strip off leading comma
echo $jobids  

sbatch --dependency=afterok:${jobids} old_sbatch_bash/hello_node_batch.sbatch

