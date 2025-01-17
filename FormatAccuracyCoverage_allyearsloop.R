# this script is a duplicate of the data wrangling part of 'MapAccuracyByCounty' 
# but with a for loop that calculates accuracy for all years

library(dplyr); library(logger); library(future); library(terra)
rm(list=ls())
# load accuracy data from LANDFIRE and USDA NASS (aggregated & formatted in 'WrangleMergedAccuracyByCounty.Rmd' script)
evt <- read.csv('./data/LANDFIRE_Accuracy/EVT_Accuracy_allregions.csv')
nvc <- read.csv('./data/LANDFIRE_Accuracy/NVC_Accuracy_allregions.csv')

# accuracy assessment missing some classes (contingency tables sometimes only have classes with auto-key plots)

all_classes <- read.csv('./data/TabularData/LF_200NVC_05142020.csv')
toadd <- dplyr::filter(all_classes, !VALUE %in% nvc$LANDFIRE_Class) %>%
  dplyr::mutate(ProducerNPlots_autokey=0)

nvc <- dplyr::full_join(nvc, dplyr::select(toadd, VALUE, NVC_Name, ProducerNPlots_autokey), 
                        by=c('LANDFIRE_Class'='VALUE', 
                             'LANDFIRE_Name' ='NVC_Name','ProducerNPlots_autokey'))

length(unique(nvc$LANDFIRE_Class)) == length(unique(nvc$LANDFIRE_Name))
length(unique(nvc$LANDFIRE_Class)) == length(unique(all_classes$VALUE))


# custom max function that returns NA if both input values are NA
mymax <- function(...,def=NA,na.rm=FALSE) {
  if(!is.infinite(x<-suppressWarnings(max(...,na.rm=na.rm)))) {
    x } else {def}
}

# for NVC classes that were taken from EVT, use the accuracy data from EVT
lf <- dplyr::full_join(nvc, evt, by=c('LANDFIRE_Class','LANDFIRE_Name', 'Region'), suffix=c('.nvc', '.evt')) %>%
  dplyr::group_by(LANDFIRE_Class, LANDFIRE_Name, Region) %>%
  dplyr::mutate(ProducerAccuracy = mymax(ProducerAccuracy.nvc, ProducerAccuracy.evt, na.rm=T),
                ProducerNPlots_autokey = mymax(ProducerNPlots_autokey.nvc, ProducerNPlots_autokey.evt, na.rm=T),
                UserAccuracy = mymax(UserAccuracy.nvc, UserAccuracy.evt, na.rm=T),
                UserNPlots_map = mymax(UserNPlots_map.nvc, UserNPlots_map.evt, na.rm=T)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(LANDFIRE_NVC = paste(LANDFIRE_Class, LANDFIRE_Name))


# specify classes that COULD have plots in auto-key (are non-managed, not agriculture or NLCD developed)
nvc_agclasses <- c(7960:7999) # classes in LANDFIRE NVC that are agriculture

managed_classes <- lf$LANDFIRE_Class[grepl(lf$LANDFIRE_Name, pattern='Developed-') | 
                                       grepl(lf$LANDFIRE_Name, pattern='Recently Burned-') | 
                                       grepl(lf$LANDFIRE_Name, pattern='Recently Logged-') | 
                                       grepl(lf$LANDFIRE_Name, pattern='Recently Disturbed Other-') | 
                                       #grepl(lf$LANDFIRE_Name, pattern='Forest Plantation') | 
                                       lf$LANDFIRE_Class %in% nvc_agclasses |
                                       lf$LANDFIRE_Name == 'Open Water']

library(dplyr)
# read county shapefile, remove polygons that are NA for county name (usually sections of water adjacent a state)
county_shp <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
  dplyr::filter(!is.na(COUNTY))

# add NVC region to county shapefile
# load region shapefile and reproject to match counties
regions <- sf::st_read('./data/SpatialData/LANDFIRE/us_lf_zones/us_lf_zones.shp') %>%
  dplyr::group_by(LF2010_GA) %>%
  summarize(geometry = sf::st_union(geometry)) %>% # original region shapefile had multiple polygons per region, so I dissolve them
  sf::st_transform(crs = sf::st_crs(county_shp)) # project region polygon to match counties

plot(regions)

# convert county polygons to centroids and calculate intersection between regions and county centroids
la <- sf::st_centroid(county_shp) %>% 
  sf::st_join(regions, join=sf::st_intersects) %>%
  dplyr::rename(LF2010_Region=LF2010_GA) %>%
  sf::st_drop_geometry() %>%
  dplyr::select(FIPS, LF2010_Region) %>%
  dplyr::arrange(FIPS)

# add region column to original county shapefile
county <- dplyr::arrange(county_shp, FIPS) %>% cbind(la) %>%
  dplyr::group_by(FIPS, STATE, COUNTY, STATE_FIPS, LF2010_Region) %>%
  summarize(geometry = sf::st_combine(geometry)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(!duplicated(paste0(STATE, COUNTY)))

#sf::st_write(county, './data/SpatialData/us_counties_better_coasts_LFregion.shp', append=F)

# read NVC pixel frequency data
nvc_county <- read.csv('./data/PixelFreq/NVC_CountyPixelFreq.csv') %>%
  dplyr::filter(!is.na(County)) %>%
  dplyr::group_by(State, County) %>%
  dplyr::mutate(PctCounty = (NCells/sum(NCells))*100) %>%
  dplyr::ungroup() 

# are there any counties in county shapefile that are NOT in dataset on NVC pixel frequency?
paste0(county$COUNTY, ", ", county$STATE)[!paste0(county$COUNTY, ", ", county$STATE) %in% paste0(nvc_county$County, ", ", nvc_county$State)]

nvc_county <- sf::st_drop_geometry(county) %>%
  dplyr::select(STATE, COUNTY, LF2010_Region) %>%
  dplyr::left_join(nvc_county, by=c('STATE'='State', 'COUNTY'='County'))

# how many classes in spatial data are missing from tabular data?
sort(unique(nvc_county$Class[!nvc_county$Class %in% lf$LANDFIRE_Class]))

# filter tabular data to ONLY classes in spatial data
lf2 <- dplyr::filter(lf, LANDFIRE_Class %in% nvc_county$Class)

# write clean version of tabular data
write.csv(lf, './data/NVC_Accuracy_allregions_cleaned.csv', row.names=F)

# join accuracy values to pixel frequency data
nvc_accuracy <- dplyr::left_join(nvc_county, lf, by=c('Class'='LANDFIRE_Class', 'LF2010_Region'='Region')) %>%
  dplyr::select(-contains('.evt') , -contains('.nvc'))

# why are there some counties with NA for NVC value?
nvc_accuracy[is.na(nvc_accuracy$Class),]

# make new variable of reference database status (well-represented, poorly-represented, absent, or managed/ag)
nvc_accuracy$RFDB_Status <- if_else(nvc_accuracy$Class %in% managed_classes, 'absent, managed/ag/disturbed', 
                                    if_else((nvc_accuracy$ProducerNPlots_autokey == 0|is.na(nvc_accuracy$ProducerNPlots_autokey)) & 
                                              !nvc_accuracy$Class %in% managed_classes,  'absent, could be added', 
                                            if_else(nvc_accuracy$ProducerNPlots_autokey >= 30, 'well-represented',
                                                    if_else(nvc_accuracy$ProducerNPlots_autokey < 30 & nvc_accuracy$ProducerNPlots_autokey > 0, 'poorly-represented',
                                                            'uh oh'))))


# calculate total number of cells per county as well as accuracy*NCells of a specific class (will sum in next step to get area-weighted average)
nvc_accuracy <- dplyr::group_by(nvc_accuracy, STATE, COUNTY) %>%
  dplyr::mutate(NCells_County= sum(NCells), Weight_ProdAcc = NCells*ProducerAccuracy,
                Weight_UserAcc = NCells*UserAccuracy)

# summarize ncell and accuracy by county and reference db status
# accuracy only applies to well-represented, but we will map data coverage of well and poorly represented classes
nvc_accuracy_bycounty <-  nvc_accuracy  %>%  
  dplyr::group_by(STATE, COUNTY, NCells_County, RFDB_Status) %>%
  dplyr::summarize(NCells_Group = sum(NCells, na.rm=T), 
                   Weight_ProdAcc = sum(Weight_ProdAcc, na.rm=T)/NCells_Group,
                   Weight_UserAcc = sum(Weight_UserAcc, na.rm=T)/NCells_Group, .groups='keep') %>%
  dplyr::mutate(RFDB_Status2=RFDB_Status) %>%
  dplyr::ungroup()

# reshape ncells to wide format
ncells <- tidyr::pivot_wider(nvc_accuracy_bycounty, id_cols=c(STATE:COUNTY, NCells_County), names_from=RFDB_Status, 
                             values_from=NCells_Group) %>%
  tidyr::replace_na(list(`well-represented` = 0, `poorly-represented` = 0))

# reshape accuracy to wide format, filter to only well-represented classes
acc <- dplyr::filter(nvc_accuracy_bycounty, RFDB_Status == 'well-represented') %>% 
  tidyr::pivot_wider(id_cols=c(STATE:COUNTY, NCells_County), names_from=RFDB_Status, 
                     values_from=c(Weight_ProdAcc, Weight_UserAcc)) %>%
  dplyr::rename(WtdUserAcc = `Weight_UserAcc_well-represented`, WtdProdAcc = `Weight_ProdAcc_well-represented`)

# translate ncells to percentage of un-managed area in each county
toplot <- dplyr::mutate(ncells, NCells_Unmanaged = (NCells_County - `absent, managed/ag/disturbed`),
                        Rep_PctUnmanaged = ((`well-represented` + `poorly-represented`)/NCells_Unmanaged)*100,
                        WellRep_PctUnmanaged = ((`well-represented`)/NCells_Unmanaged)*100)

names(county)

for (CDLYear in c(2012:2021)) {
  # load accuracy data
  cdl <- read.csv('./data/CDL_Accuracy/CDL_accuracy_long_allstates_2012to2021.csv')
  # filter cdl to selected year to match pixel freq data
  cdl_oneyear <- dplyr::filter(cdl, Year %in% CDLYear)
  
  # key to group CDL classes in arable or non-arable
  cdl_classes <- read.csv('./data/TabularData/NASS_classes_pasture_is_arable.csv')
  ag_in_cdl <- cdl_classes$VALUE[cdl_classes$GROUP == 'A']
  
  # load frequency data
  cdl_freq <- read.csv(paste0('./data/PixelFreq/CDL', CDLYear, '_CountyPixelFreq.csv'))
  
  head(cdl_freq)
  head(cdl_oneyear)
  
  cdl_accuracy <- dplyr::left_join(cdl_freq, cdl_oneyear,  by=c('Class'='CDL_Class', 'State')) %>%
    dplyr::mutate(GT_Status = if_else(is.na(Producer), "no ground-truth", "present")) %>%
    dplyr::group_by(Year, State, County) %>%
    dplyr::mutate(NCells_County = sum(NCells)) %>%
    dplyr::filter(Class %in% ag_in_cdl) %>% # filter down to ONLY agricultural classes
    dplyr::mutate(NCells_Arable = sum(NCells), Weight_ProdAcc = NCells*Producer,
                  Weight_UserAcc = NCells*User)
  
  cdl_accuracy_bycounty <- cdl_accuracy  %>%
    dplyr::group_by(Year, State, County, NCells_County, NCells_Arable, GT_Status) %>% 
    dplyr::summarize(NCells_Group = sum(NCells, na.rm=T), 
                     Weight_ProdAcc = sum(Weight_ProdAcc, na.rm=T)/NCells_Group,
                     Weight_UserAcc = sum(Weight_UserAcc, na.rm=T)/NCells_Group, .groups='keep') %>%
    dplyr::mutate(GT_Status2=GT_Status) %>%
    dplyr::ungroup()
  
  # reshape ncells to wide format
  ncells_cdl <- tidyr::pivot_wider(cdl_accuracy_bycounty, id_cols=c(Year:County, NCells_County, NCells_Arable), 
                                   names_from=GT_Status, 
                                   values_from=NCells_Group) %>%
    tidyr::replace_na(list(`present` = 0, `no ground-truth` = 0)) %>%
    dplyr::mutate(PresentGT_PctArable = (`present`/NCells_Arable)*100, 
                  CountyPctArable = (NCells_Arable/NCells_County)*100)
  
  # reshape accuracy to wide format, filter to only well-represented classes
  acc_cdl <- dplyr::filter(cdl_accuracy_bycounty, GT_Status == 'present') %>% 
    tidyr::pivot_wider(id_cols=c(Year:County, NCells_Arable), names_from=GT_Status, 
                       values_from=c(Weight_ProdAcc, Weight_UserAcc)) %>%
    dplyr::rename(WtdUserAcc = `Weight_UserAcc_present`, WtdProdAcc = `Weight_ProdAcc_present`)
  
  library(classInt); library(ggplot2); library(viridis); library(dplyr)
  
  # join results to spatial object for mapping
  toplot_nvc <- dplyr::left_join(toplot, acc) %>%
    dplyr::left_join(acc) %>%
    dplyr::select(-starts_with('absent'), -contains('represented')) %>%
    dplyr::mutate(Dataset='Natural land', 
                  Dataset_Name='NVC',
                  FocalGroup_PctCounty=(NCells_Unmanaged/NCells_County)*100) %>%
    dplyr::mutate(WithData_PctFocalGroup=WellRep_PctUnmanaged,
                  NCells_FocalGroup = NCells_Unmanaged) %>%
    dplyr::rename(State=STATE, County=COUNTY)                 
  
  # join results to spatial object for mapping
  toplot_cdl <- dplyr::left_join(acc_cdl, ncells_cdl) %>%
    dplyr::mutate(Dataset='Agricultural land', 
                  Dataset_Name='CDL') %>%
    dplyr::mutate(FocalGroup_PctCounty=CountyPctArable, 
                  WithData_PctFocalGroup=PresentGT_PctArable,
                  NCells_FocalGroup=NCells_Arable) %>%
    dplyr::select(-Year)
  
  # read data on merged accuracy calculated in 'WrangleMergedAccuracyByCounty.Rmd'
  toplot_merged <- read.csv(paste0('./data/MergedAccuracy_', CDLYear, ".csv")) %>%
    dplyr::select(STATE, COUNTY, NCells_County, NCells_CDL, starts_with('Wtd'), well.represented) %>%
    dplyr::rename(County=COUNTY, State=STATE) %>%
    dplyr::mutate(Dataset='Natural + Agricultural land',
                  Dataset_Name = 'NVC+CDL') %>%
    dplyr::left_join(dplyr::select(toplot_nvc, State, County, NCells_Unmanaged)) %>%
    dplyr::mutate(WithData_PctFocalGroup = (well.represented / (NCells_Unmanaged + NCells_CDL))*100, 
                  FocalGroup_PctCounty = ((NCells_Unmanaged + NCells_CDL)/NCells_County)*100,
                  NCells_FocalGroup = (NCells_Unmanaged + NCells_CDL)) %>%
    dplyr::select(-NCells_Unmanaged)
  
  toplot_both <- dplyr::full_join(toplot_nvc, toplot_cdl) %>%
    dplyr::full_join(toplot_merged)
  
  toplot_both <- dplyr::left_join(county, toplot_both, by = c('STATE'='State', 'COUNTY'='County'))
  
  saveRDS(toplot_both, paste0('./data/TechnicalValidation/summarized_accuracy_data_CDL', CDLYear, '_NVC_Merged.rds'))
}