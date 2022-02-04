#!/bin/bash

tier='1:2:3'

for year in 2012 2013 2014 2015 2016 2017 2018 2019 2020
#for year in 2020

do

sbatch --job-name="Mosaic$year" --export=ALL,cdlyear="$year",tier="$tier" MosaicToNational.sbatch
sleep 1s

done
