srun -A geoecoservices --partition=bigmem --pty --preserve-env bash

cd /project/geoecoservices/MergeLANDFIREandCDL/data/TechnicalValidation/Mismatch_spatial

module load singularity
singularity shell ../../../../Containers/geospatial_extend_v1.57.sif

# specify years to loop
years=(2021 2020 2019 2018 2017 2016 2015 2014 2013 2012)

# make separate directory for each year
mkdir $year
# move files matching the specified year to year directory 
mv *CDL$year*.gpkg $year

# merge vector layers from all four regions into one geopackage
for year in "${years[@]}"
do
ogrmerge.py -nln CDL${year} -single -overwrite_layer -progress -o MismatchedPixels_CDL${year}_NVC2016.gpkg \
    ${year}/*
done

