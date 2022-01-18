#!/bin/bash

#for year in 2013 2014 2015 2018 2020
for year in 2020
do
sbatch --job-name=MosaicTexas$year --export=ALL,terra=TRUE,gdal=FALSE,compress=TRUE RunTexas.sbatch
sleep 1s

#sbatch --job-name=MosaicTexas$year --export=ALL,terra=FALSE,gdal=TRUE RunTexas.sbatch
sleep 1s
done
