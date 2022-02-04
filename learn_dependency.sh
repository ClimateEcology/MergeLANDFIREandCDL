#!/bin/bash

# Get first job id

jid=$(sbatch old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)

# Remainder jobs
for k in {2..4};
    do 
        jid=$(sbatch --dependency=afterok:${jid} old_sbatch_bash/hello_node_batch.sbatch | cut -d ' ' -f4)
    done