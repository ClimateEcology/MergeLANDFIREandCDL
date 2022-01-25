#!/bin/bash

#for year in 2012 2013 2014 2015 2016 2017 2018 2019 2020
for year in 2020

do

sbatch --job-name="Tests$year" --export=ALL,cdlyear="$year" RunTests.sbatch
sleep 1s

done
