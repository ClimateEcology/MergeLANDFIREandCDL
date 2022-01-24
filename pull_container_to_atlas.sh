# start service partition to avoid going over cpu limit on login
srun -A geoecoservices --partition=service --time=01-00:00 --pty --preserve-env bash

# load singularity and clear cache
module load singularity/3.5.2
singularity cache clean

# pull desired version of container
singularity pull docker://melaniekamm/geospatial_extend:v1.2

# rename container on Atlas to match all sbatch scripts
rm geospatial_extend_latest.sif # remove old version of container (if there is one)
cp geospatial_extend_v1.2.sif geospatial_extend_latest.sif # create updated container with same name
