#!/bin/bash

tiles=TRUE
merge=TRUE
mosaic=TRUE
allstates=FALSE

#for year in 2013 2014 2015 2018 2020
for year in 2020
do
sbatch --job-name=Texas$year --export=ALL,cdlyear=$year,region='Southeast',\
mktiles=$tiles,runmerge=$merge,mosaic=$mosaic,allstates=$allstates RunTexas.sbatch
sleep 1s

done
