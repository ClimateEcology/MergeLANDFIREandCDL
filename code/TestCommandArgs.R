rm(list=ls())

# import function to merge together CDL and LANDFIRE tiles
source('./code/functions/merge_landfire_cdl_4tiles.R')
source('./code/functions/grid_rasters.R')

library(dplyr);  library(raster); library(sf); library(logger); library(future)

args <- commandArgs(trailingOnly = T)

# specify input parameters
logger::log_info(paste0('arg 1 is ', args[1]))
logger::log_info(paste0('arg 2 is ', args[2]))
logger::log_info(paste0('arg 3 is ', args[3]))


CDLYear <- args[2] # year of NASS Cropland Data Layer
regionName <- args[2] # region to process