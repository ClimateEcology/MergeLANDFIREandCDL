#!/bin/bash

module load singularity/3.5.2
singularity exec --bind /90daydata:/90daydata geospatial_extend_latest.sif Rscript code/InitialSetup_wInternet.R


