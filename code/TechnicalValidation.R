# technical validation looking at the distribution of mis-matched pixels in merge CDL and LANDFIRE workflow
library(dplyr)
source('./code/functions/addcounty.R')

valdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/ValidationData/'

tiles <- list.files(valdir, full.names = T)
increment <- 50

h <- seq(from=1, to=length(tiles), by=increment)

for (j in h) {
torun <- c(j:(j+ (increment-1)))

# if the last group exceed the number of files, shorten the list
if (any(torun > length(tiles))) {
  torun <- torun[1]:length(tiles)
}

  for (i in torun) {
    # load csv of mismatch pixel data for one tile
    ex <- addcounty(tiles[i])
    
    if (i == torun[1]) {
      all <- ex
    } else {
      assign(x=paste0('group', j), value=rbind(all, ex)) # combine info for all tiles into one file
    }
  }
logger::log_info(paste0(j,' files out of ', max(h), ' are finished.'))
}

for (i in 1:length(h)) {

  # paste together results
  one <- get(paste0('group', h[i]))

  if (i == 1) {
    all <- one
  } else {
    all <- rbind(all, one) # combine info for all tiles into one file
  }
}

freq_bystate <- dplyr::mutate(all, PctTile = 1/ncells_tile) %>% 
  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))

freq_bycounty <- dplyr::mutate(all, PctTile = 1/ncells_tile) %>% 
  dplyr::group_by(NVC_Class, CDL_Class, CDLYear, State, FIPS) %>%
  dplyr::summarise(Mismatch_NCells = n(), Mismatch_PctTile = sum(PctTile))


write.csv(freq_bystate, './data/TechnicalValidation/Mismatched_Cells_byState.csv')
write.csv(freq_bycounty, './data/TechnicalValidation/Mismatched_Cells_byCounty.csv')
write.csv(all, './data/TechnicalValidation/Mismatch_ByCell.csv')

