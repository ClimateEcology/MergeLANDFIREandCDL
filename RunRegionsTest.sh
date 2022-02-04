#!/bin/bash

tiles=TRUE
merge=TRUE
mosaic=TRUE
allstates=TRUE

# declare empty string for all job ids
jobids=""

for year in 2020 2019

do
    seid=$(sbatch --job-name="SouthE$year" \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    neid=$(sbatch --job-name="NorthE$year" \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    mwid=$(sbatch --job-name="MidW$year" \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    wid=$(sbatch --job-name="West$year" \
    old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    sleep 1s

    jobids="$jobids,$seid,$neid,$mwid,$wid"
done

jobids="${jobids:1}" # strip off leading comma
echo $jobids  

sbatch --dependency=afterok:${jobids} old_sbatch_bash/hello_node_batch.sbatch

