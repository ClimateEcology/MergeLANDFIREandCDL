library(dplyr); library(ggplot2)
#rm(list=ls())

la <- readRDS('./data/summary_pct_mismatch_la.RDS')
toplot <- readRDS('./data/summary_pct_mismatch_toplot.RDS')
toplot_both <- readRDS('./data/TechnicalValidation/summarized_accuracy_data_CDL_NVC_Merged.rds')
year <- 2017

# summary by class
mismatch_summary <- la %>% filter(CDLYear == year) %>% 
  dplyr::filter(variable_type == 'NCells_Mismatch') %>%
  dplyr::group_by(NVC_SpecificClass, CDLYear) %>% 
  summarize(NCells_Class = unique(NCells_Class), value = sum(value)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(PercentNVCClass = (value/NCells_Class)*100,
                PercentAg = NCells_Class/sum(NCells_Class)*100)



proportional_tradeoff <- mismatch_summary %>% ggplot2::ggplot() +
  geom_point(aes(x=PercentNVCClass, y=PercentAg, color=NVC_SpecificClass)) +
  ggrepel::geom_text_repel(aes(x=PercentNVCClass, y=PercentAg, label = NVC_SpecificClass, color=NVC_SpecificClass),
                   point.padding = 0.35) +
  xlab('Percent of NVC pixels that mismatch with CDL') +
  ylab('Percent of U.S. agricultural land') +
  theme_classic(base_size=14) + 
  scale_color_manual(values=c("#5e904e", "#610489", "#21a708", "#c052e4", "#1b1345", "#6c93c5", "#085782", "#fd048f", "#334aab")) +
  theme(legend.position = "none")

proportional_tradeoff

ggplot2::ggsave(plot=proportional_tradeoff, './figures/PercentAgLandvsPercentClassMismatch.svg', width=6, height=4.5)



sum_land <- mismatch_summary %>%
  mutate(high_pctmismatch = if_else(NVC_SpecificClass %in% c('Bush fruit and berries', 'Orchard', 'Vineyard', 'Aquaculture') , 'yes', 'no')) %>%
  dplyr::group_by(high_pctmismatch) %>%
  summarize(NCells_Group = sum(NCells_Class)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(PercentArea = NCells_Group/sum(NCells_Group) * 100)
  
major_classes <- mismatch_summary %>%
  #filter(PercentAg > 5) %>%
  summarize(PctMismatchNational = (sum(value)/sum(NCells_Class))*100)


mismatch_summary$NCells_Class/(mismatch_summary$PercentAg/100)

summap2017 <- dplyr::filter(toplot, CDLYear == year)


length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 24]))
length(unique(summap2017$FIPS))


length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 6]))/length(unique(summap2017$FIPS))
length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 13]))/length(unique(summap2017$FIPS))      
length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 24]))/length(unique(summap2017$FIPS))


unresolved_conflicts <- read.csv('./data/TechnicalValidation/FinalRaster_FreqPixelsUnresolvedConflict.csv') %>%
  dplyr::mutate(NCellsCounty = NCells/PctCounty)

national <- unresolved_conflicts %>%
  dplyr::summarise(NCellsUnresolvedNational = sum(NCells, na.rm=T),
                   UnresolvedNational_PctAg = (NCellsUnresolvedNational/1987553832)*100)


length(unique(unresolved_conflicts$FIPS[unresolved_conflicts$PctCounty < 0.4]))/length(unique(unresolved_conflicts$FIPS))
length(unique(unresolved_conflicts$FIPS[unresolved_conflicts$PctCounty > 4.55]))


library(dplyr); library(spatstat); library(ggplot2)
# summarize accuracy data too 

# national weighted average
accuracy <- readRDS('./data/TechnicalValidation/summarized_accuracy_data_CDL_NVC_Merged.rds')
                    
user_bystate <- accuracy %>% filter(WtdUserAcc < 0.368 & Dataset_Name == 'NVC') %>%
  as.data.frame() %>%
  dplyr::group_by(STATE) %>%
  dplyr::summarise(NCounties = n())

prod_bystate <- accuracy %>% filter(WtdProdAcc < 0.368 & Dataset_Name == 'NVC') %>%
  as.data.frame() %>%
  dplyr::group_by(STATE) %>%
  dplyr::summarise(NCounties = n())

national_accuracy <- accuracy %>%
  as.data.frame() %>%
  group_by(Dataset_Name) %>%
  dplyr::mutate(RelArea = NCells_County/sum(NCells_County)) %>%
  dplyr::summarize(WtdMeanUser = sum(WtdUserAcc*RelArea), 
                   WtdMeanProd = sum(WtdProdAcc*RelArea),
                   WtdMedianUser = weighted.median(WtdUserAcc, w=RelArea), 
                   WtdMedianProd = weighted.median(WtdProdAcc, w=RelArea),
                   WtdMedianDC = weighted.median(WithData_PctFocalGroup, w=RelArea))
  

long_accuracy <- accuracy %>% 
  as.data.frame() %>%
  dplyr::select(FIPS, Dataset_Name, WtdProdAcc, WtdUserAcc) %>%
  tidyr::pivot_longer(contains('Wtd'), names_to='AccuracyType')

long_accuracy %>% ggplot(aes(AccuracyType, value, fill=AccuracyType)) +
  geom_boxplot() +
  facet_wrap(~Dataset_Name) +
  xlab("") +
  theme_classic(base_size=16) +
  theme(legend.position="none")

accuracy_hist <- long_accuracy %>% ggplot(aes(value, col=AccuracyType)) +
  geom_density(lwd=1) +
  xlab("Classification accuracy by county,\n area-weighted") +
  theme_classic(base_size=14) +
  facet_wrap(~Dataset_Name, ncol=1) + 
  scale_color_discrete(name = "Accuracy type", labels = c("producer's", "user's"))

ggplot2::ggsave(plot=accuracy_hist, filename='./figures/AccuracyHistogram.svg', device='svg', width=5, height=6)

# data coverage histogram
accuracy %>% ggplot(aes(Dataset_Name, WithData_PctFocalGroup, fill=Dataset_Name)) +
  geom_boxplot() +
  #facet_wrap(~Dataset_Name) +
  xlab("") +
  theme_classic(base_size=16) +
  theme(legend.position="none")

dc_hist <- accuracy %>% ggplot(aes(WithData_PctFocalGroup)) +
  geom_density(lwd=1) +
  xlab("Coverage of reference data, by county") +
  theme_classic(base_size=14) +
  facet_wrap(~Dataset_Name, ncol=1, scales='free')
dc_hist

ggplot2::ggsave(plot=dc_hist, filename='./figures/DataCoverageHistogram.svg', device='svg', width=4.1, height=6)

# look at accuracy vs data coverage
toplot_long <- toplot_both %>%
  dplyr::select(-starts_with('no'), -present) %>%
  tidyr::pivot_longer(cols=WtdProdAcc:WtdUserAcc, names_to='Accuracy_Type', values_to='Accuracy') %>%
  dplyr::mutate(`Accuracy_Type` = if_else(`Accuracy_Type` == 'WtdProdAcc', 'Producer Accuracy', 'User Accuracy'))

library(ggplot2)
coverage_accuracy <- toplot_long %>%
  #dplyr::filter(Dataset_Name == 'NVC') %>%
  ggplot(aes(x=WithData_PctFocalGroup, y=Accuracy)) +
  geom_point() +
  geom_smooth(formula = y ~ s(x, bs = "tp")) +
  theme_classic(base_size=14) +
  xlab("Coverage of reference data") +
  facet_wrap(~Dataset_Name + Accuracy_Type, ncol=2)

ggsave(plot=coverage_accuracy, filename= paste0('./figures/Accuracy_vs_DataCoverage_', CDLYear, '.svg'),  width=6.5, height=8)
