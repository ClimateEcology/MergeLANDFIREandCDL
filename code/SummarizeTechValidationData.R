library(dplyr); library(future)

args <- commandArgs(trailingOnly = T)
parallel <- args[2] # aggregate data using parallel processing
nprocess <- args[3]

nprocess <- 'all'
parallel <- T

valdir <- '../../../90daydata/geoecoservices/MergeLANDFIREandCDL/ValidationData/'
source('./code/functions/summarize_techval.R')


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


logger::log_info('Reading giant file of by pixel results.')

all <- data.table::fread(paste0('./data/TechnicalValidation/run', nprocess, '/Mismatch_ByCell_run', 
                             nprocess, '_group', increment, '_', par_text, '.csv'))

logger::log_info('Giant file successfully read.')

logger::log_info('Split data frame into each CDL year, summarize n mis-matched pixels and join results.')

years <- sort(unique(all$CDLYear)) # specify which years are in giant file

#turn on parallel processing for furrr package
future::plan(multisession)

freq_bycounty <- furrr::future_map_dfr(.x=years, .f=summarize_techval,
                                       in_data=all,
                                       .options=furrr::furrr_options(seed = T))
# stop parallel processing
future::plan(sequential)

logger::log_info('Writing output files.')

if(!dir.exists(paste0('./data/TechnicalValidation/run', nprocess))) {
  dir.create(paste0('./data/TechnicalValidation/run', nprocess))
}

# write.csv(freq_bystate, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatched_Cells_byState_run', 
#                                nprocess,  '_group', increment, '_', par_text, '.csv'))
write.csv(freq_bycounty, paste0('./data/TechnicalValidation/run', nprocess, '/Mismatched_Cells_byCounty_run', 
                                nprocess, '_group', increment, '_', par_text, '.csv'))

