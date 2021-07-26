#!/bin/bash
#SBATCH -p bigmem #partition to use
#SBATCH -N 1 #number of nodes in this job
#SBATCH --cpus-per-task=24 #number of cpus to use for each task
#SBATCH -t 72:00:00 #time allocated for this job hours:mins:seconds
#SBATCH -A geoecoservices  #substitute with the name of your project
#SBATCH -o "stdout.%j.%N" # standard out %j adds job number to outputfile name and %N adds the node name
#SBATCH -e "stderr.%j.%N" #optional but it prints our standard error
#SBATCH --mail-user=melanie.kammerer@usda.gov #enter your email address to receive emails
#SBATCH --mail-type=BEGIN,END,FAIL #will receive an email when job starts, ends or fails

export OPENBLAS_NUM_THREADS=1
module load singularity
singularity exec geospatial_extend_latest.sif Rscript code/RunMergeLANDFIREandCDL_byState.R --args ${cdlyear} ${region} ${mktiles} ${runmerge}


