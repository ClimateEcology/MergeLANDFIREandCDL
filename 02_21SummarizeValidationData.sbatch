#!/bin/bash
#SBATCH --job-name="SummarizeTechnVal" #name of the job submitted
#SBATCH -p bigmem #partition to use
#SBATCH -N 1 #number of nodes in this job
#SBATCH --cpus-per-task=24 #number of cpus to use for each task
#SBATCH --mem=1500GB #request all memory on a node
#SBATCH -t 90:00:00 #time allocated for this job hours:mins:seconds
#SBATCH -A geoecoservices  #substitute with the name of your project
#SBATCH -o "stdout.%j.%N" # standard out %j adds job number to outputfile name and %N adds the node name
#SBATCH -e "stderr.%j.%N" #optional but it prints our standard error
#SBATCH --mail-user=melanie.kammerer@usda.gov #enter your email address to receive emails
#SBATCH --mail-type=BEGIN,END,FAIL #will receive an email when job starts, ends or fails

export OPENBLAS_NUM_THREADS=1
module load singularity/3.5.2
singularity exec --bind /90daydata:/90daydata $container Rscript code/SummarizeTechValidationData.R\
 --args parallel=TRUE nprocess=all

