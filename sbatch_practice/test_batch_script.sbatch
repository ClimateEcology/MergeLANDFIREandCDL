#!/bin/bash
#SBATCH --job-name "TestMergeRasters" #name of the job submitted
#SBATCH -N 1 #number of nodes in this job
#SBATCH --cpus-per-task=12 #number of cpus to use for each task
#SBATCH -t 01:00:00 #time allocated for this job hours:mins:seconds
#SBATCH -A geoecoservices  #substitute with the name of your project
#SBATCH --mail-user=melanie.kammerer@usda.gov #enter your email address to receive emails
#SBATCH --mail-type=BEGIN,END,FAIL #will receive an email when job starts, ends or fails
#SBATCH -o "stdout.%j.%N" # standard out %j adds job number to outputfile name and %N adds the node name
#SBATCH -e "stderr.%j.%N" #optional but it prints our standard error

module load r
Rscript --vanilla ../code/02-mclapply.R


