rm(list=ls())

##### pixel mis-match (after step 1 of geospatial workflow) as number of cells and proportion

mismatch_byyearcounty <- readRDS('./data/DataToReformat/pixel_mismatch_byyear_bycounty.RDS')

head(mismatch_byyearcounty)


mismatch_byyearcounty <- mismatch_byyearcounty %>%
  dplyr::arrange(FIPS) %>%
  dplyr::mutate(FIPS = stringr::str_pad(FIPS, 5, pad="0")) %>%# reformat FIPS to have leading zeros
  dplyr::rename(NVC_Name = NVC_SpecificClass,
                NCells_NVCClass_perCounty = NCells_Class,
                NVC_CDL_Pair = NVC_CDL_Named,
                CDL_Year = CDLYear,
                STATE = State) %>%
  dplyr::select(FIPS, STATE, CDL_Year, everything())


if (!dir.exists('./data/DataToArchive')) {
  dir.create('./data/DataToArchive')
}

mismatch_byyearcounty %>% data.table::fwrite('./data/DataToArchive/pixel_mismatch_byyear_bycounty.csv')


###### unresolved pixels

for (CDLYear in c(2012:2021)) {
  library(dplyr)
  # read county shapefile with LANDFIRE regions
  county <- sf::st_read('./data/SpatialData/us_counties_better_coasts_LFregion.shp') %>%
    dplyr::rename(LF2010_Region=LF2010_) # fix column name that was abbreviated by shp driver
  
  # read NVC/CDL pixel frequency data
  merged_freq <- read.csv(paste0('./data/PixelFreq/CDL', CDLYear, 'NVC_CountyPixelFreq.csv')) %>%
    dplyr::filter(!is.na(County)) %>%
    dplyr::group_by(State, County) %>%
    dplyr::mutate(PctCounty = (NCells/sum(NCells)) *100) %>%
    dplyr::ungroup()
  
  # are there any counties in county shapefile that are NOT in dataset on NVC pixel frequency?
  paste0(county$COUNTY, ", ", county$STATE)[!paste0(county$COUNTY, ", ", county$STATE) %in% paste0(merged_freq$County, ", ", merged_freq$State)]
  
  # join pixel frequency with LF regions
  merged_freq_sf <- county %>%
    dplyr::select(FIPS, STATE, COUNTY, LF2010_Region) %>%
    dplyr::left_join(merged_freq, by=c('STATE'='State', 'COUNTY'='County'))
  
  # join pixel frequency with LF regions
  merged_freq <- sf::st_drop_geometry(county) %>%
    dplyr::select(STATE, COUNTY, LF2010_Region) %>%
    dplyr::left_join(merged_freq, by=c('STATE'='State', 'COUNTY'='County'))
  
  
  # fill in a few missing polygons that show up on no data map
  counties <- sf::st_read('./data/SpatialData/us_counties_better_coasts.shp') %>%
    dplyr::filter(!is.na(COUNTY))
  
  nodata_freq <- merged_freq_sf %>%
    sf::st_drop_geometry() %>%
    dplyr::filter(Class == -1001)
  
  nodata <- counties %>%
    dplyr::select(FIPS, STATE, COUNTY) %>%
    dplyr::left_join(nodata_freq) %>%
    tidyr::replace_na(list(PctCounty=0))
  
  oneyear <- sf::st_drop_geometry(nodata) %>%
    dplyr::rename(MergedRasterClass = Class) %>%
    dplyr::mutate(CDL_Year = CDLYear,
                  MergedRasterName = 'CDL/NVC mismatch, unresolved conflict') %>%
    dplyr::select(FIPS, STATE, CDL_Year, COUNTY, LF2010_Region, MergedRasterClass, MergedRasterName, everything())
  
  if (CDLYear == 2012) {
    allyears <- oneyear
  } else if (CDLYear > 2012) {
    allyears <- rbind(allyears, oneyear)
  }
}

head(allyears)
head(mismatch_byyearcounty)

unique(allyears$CDL_Year)

allyears %>% data.table::fwrite('./data/DataToArchive/unresolved_conflict_byyear_bycounty.csv')

sort(unique(allyears$FIPS))


###### accuracy and data coverage of cdl, nvc, and merged dataset
for (CDLYear in c(2012:2021)) {
  
  accuracy_datacoverage <- readRDS(paste0('./data/TechnicalValidation/summarized_accuracy_data_CDL', 
                                          CDLYear, '_NVC_Merged.rds')) %>%
    sf::st_drop_geometry() %>%
    mutate(CDL_Year = CDLYear) %>%
    dplyr::select(FIPS, STATE, CDL_Year, COUNTY, Dataset, Dataset_Name, 
                  NCells_County, NCells_FocalGroup,
                  FocalGroup_PctCounty, WithData_PctFocalGroup, 
                  WtdProdAcc, WtdUserAcc)

  if (CDLYear == 2012)
    allyears_accuracy <- accuracy_datacoverage
  else {
    allyears_accuracy <- rbind(allyears_accuracy, accuracy_datacoverage)
  }
}

allyears_accuracy %>% data.table::fwrite('./data/DataToArchive/accuracy_datacoverage_byyear_bycounty.csv')
