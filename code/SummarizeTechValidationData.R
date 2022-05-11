

nprocess <- 'all'
parallel <- T

valdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/ValidationData/'

# if not processing all available data, make sure R knows nprocess is a number
if (nprocess != 'all') {
  nprocess <- as.numeric(nprocess)
} else if (nprocess == 'all'){
  nfiles <- length(list.files(valdir))
}

if (parallel == T) {
  increment <- max(2, round(nfiles/10, digits=0)) # org 20
  par_text <- 'parallel'
} else if (parallel == F) {
  increment <- max(2, round(nfiles/50, digits=0)) # org 100
  par_text <- 'notparallel'
}



all <- data.table::fread(paste0('./data/TechnicalValidation/run', nprocess, '/Mismatch_ByCell_run', 
                             nprocess, '_group', increment, '_', par_text, '.csv'))

cleaned <- dplyr::mutate(all, PctTile = 1/ncells_tile) %>% 
  dplyr::filter(!is.na(FIPS)) %>% # remove mis-match points that do not have FIPS code (overlap water or other non-county polygon)
  dplyr::group_by(CDLYear) %>% # group by year to avoid removing the same pixels that appear in multiple years
  dplyr::mutate(coord = (paste0(x, y))) %>%
  dplyr::distinct(coord, .keep_all=T)  # remove points that might be duplicated 
#duplication could happen due to calculating mis-match from state tiles rather than actual state polygons, borders don't match exactly

freq_bystate <- cleaned %>%  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile, rm.na=T))

logger::log_info('Finished summarize by state, starting summarize by county.')

freq_bycounty <- cleaned %>% dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))

logger::log_info('Writing output files.')

if(!dir.exists(paste0('./data/TechnicalValidation/run', nprocess))) {
  dir.create(paste0('./data/TechnicalValidation/run', nprocess))
}

write.csv(freq_bystate, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatched_Cells_byState_run', 
                               nprocess,  '_group', increment, '_', par_text, '.csv'))
write.csv(freq_bycounty, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatched_Cells_byCounty_run', 
                                nprocess, '_group', increment, '_', par_text, '.csv'))

