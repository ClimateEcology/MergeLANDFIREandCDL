rm(list=ls())
source('./code/functions/merge_landfire_cdl.R')

# specify input parameters
veglayer <- 'nvc' # LANDFIRE vegetation layer to use (nvc or evt)
data_dir <- './data' #directory where tabular and spatial data are stored

# read CDL class names
cdl_classes <- read.csv(paste0(data_dir, '/TabularData/NASS_classes_simple.csv')) %>% 
  dplyr::filter(VALUE < 500)  %>%#filter out CDL classes that I created for a different project
  dplyr::mutate(VALUE = as.character(-VALUE))


allow_classes <- as.numeric(cdl_classes$VALUE[cdl_classes$GROUP == 'A'])


merge_landfire_cdl(veglayer=veglayer, data_dir=data_dir)