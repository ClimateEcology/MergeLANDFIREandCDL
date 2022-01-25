
source('./code/functions/tests/check_rastersize.R')

alltiledirs <- list.dirs('../../../90daydata/geoecoservices/MergeLANDFIREandCDL', recursive=F)

# use this file path if running from 90daydata
#alltiledirs <- list.dirs(getwd(), recursive=F)

alltiledirs <- alltiledirs[grepl(alltiledirs, pattern="Tiles")]

for (onedir in alltiledirs) {
  check_rastersize(onedir, cutoff_pct=0.85)
}