#!/bin/bash

# declare empty string for all job ids
jobids=""

# Get first job id
jid=$(sbatch old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)

# Remainder jobs
for k in {2..4};
    do 
        jid=$(sbatch old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)

        jobids="$jobids,$jid"
    done
jobids="${jobids:1}" # strip off leading comma
echo $jobids  

sbatch --dependency=afterok:${jobids} old_sbatch_bash/hello_node_batch.sbatch
