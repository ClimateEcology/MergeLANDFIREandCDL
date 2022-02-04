#!/bin/bash
#SBATCH --job-name=HelloWorld 		#job name
#SBATCH --account=geoecoservices	#account name
#SBATCH --nodes 1                 	#number of nodes in this job
#SBATCH --ntasks 10                 	#number of cores/tasks in this job
#SBATCH --ntasks-per-core=1   
#SBATCH --time 00:00:30           	#time allocated for this job hours:mins:seconds


module load r
Rscript -e "paste('Hello from node', Sys.getenv('SLURMD_NODENAME'))"
