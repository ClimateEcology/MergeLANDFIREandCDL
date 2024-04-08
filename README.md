# MergeLANDFIREandCDL- Building an integrated land cover map for agricultural and natural areas


[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7065750.svg)](https://doi.org/10.5281/zenodo.7065750)


The goal of this project was to merge two major datasets, the LANDFIRE National Vegetation Classification (NVC) and USDA-NASS Cropland Data Layer (CDL), to produce an integrated land cover map. Our workflow leveraged strengths of the NVC and the CDL to produce detailed rasters comprising both agricultural and natural land-cover classes. We generated these maps for each year from 2012-2021 for the conterminous United States, quantified agreement between input layers and accuracy of our merged product, and herein publish the complete workflow necessary to update these data.

The details of these analyses are described in Kammerer et al (2024) "Not just crop or forest: an integrated land cover map for agricultural and natural areas." https://doi.org/10.1038/s41597-024-02979-w. 

All data files generated in this work are available through the USDA Ag Data Commons, split into two datasets for tabular and spatial files, respectively. Tabular data (CSV format) are available at https://doi.org/10.15482/USDA.ADC/1527977 and spatial data (GeoTiff format) are available at https://doi.org/10.15482/USDA.ADC/1527978. Please see Kammerer et al (2024) and the linked data archives for more details.

Our workflow used the following hierarchical structure:
1. Run scripts- executable shell scripts that run several SLURM scripts looping over 2012-2021 land cover data (.sh files)
2. SLURM scripts- shell scripts that specify necessary parameters for SLURM job scheduler, set singularity container as the run environment, and call geospatial scripts (.sbatch)
2. Geospatial scripts- primary specification of geospatial analyses (.R)
3. Geospatial functions- custom R functions used in geospatial scripts (.R)

Run scripts and SLURM scripts are located in the main project directory and geospatial scripts and functions in the 'code' and 'code/functions' directories, respectively. 

Please refer to the code hierarchy table ('CodeHierarchyTable.csv') for a description of each step of our workflow and associated run scripts, SLURM scripts, geospatial scripts, and functions.

