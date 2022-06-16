# summary by class
mismatch_summary <- filter(la, CDLYear == 2017) %>% 
  dplyr::group_by(NVC_SpecificClass, variable_type) %>% 
  summarize(NCells_Class = unique(NCells_Class), value = sum(value)) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(variable_type) %>%
  dplyr::mutate( PercentArea = NCells_Class/sum(NCells_Class)*100)


percent_mismatch <- dplyr::filter(mismatch_summary, variable_type == 'Pct_Mismatch') 

proportional_tradeoff <- ggplot2::ggplot(percent_mismatch) +
  geom_point(aes(x=value, y=PercentArea, color=NVC_SpecificClass)) +
  ggrepel::geom_text_repel(aes(x=value, y=PercentArea, label = NVC_SpecificClass, color=NVC_SpecificClass),
                   point.padding = 0.35) +
  xlab('Percent of NVC pixels that mismatch with CDL') +
  ylab('Percent of U.S. agricultural land') +
  theme_classic(base_size=14) + 
  scale_color_manual(values=c("#5e904e", "#610489", "#21a708", "#c052e4", "#1b1345", "#6c93c5", "#085782", "#fd048f", "#334aab")) +
  theme(legend.position = "none")

proportional_tradeoff

ggplot2::ggsave(plot=proportional_tradeoff, './figures/PercentAgLandvsPercentClassMismatch.svg', width=6, height=4.5)



sum_land <- filter(mismatch_summary, variable_type == 'NCells_Mismatch') %>%
  mutate(high_pctmismatch = if_else(NVC_SpecificClass %in% c('Bush fruit and berries', 'Orchard', 'Vineyard', 'Aquaculture') , 'yes', 'no')) %>%
  dplyr::group_by(high_pctmismatch) %>%
  summarize(NCells_Group = sum(NCells_Class)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(PercentArea = NCells_Group/sum(NCells_Group) * 100)
  

summap2017 <- dplyr::filter(toplot, CDLYear == 2017)


length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 24]))
length(unique(summap2017$FIPS))


length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 6]))/length(unique(summap2017$FIPS))
length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 13]))/length(unique(summap2017$FIPS))      
length(unique(summap2017$FIPS[summap2017$Pct_Mismatch < 24]))/length(unique(summap2017$FIPS))


unresolved_conflicts <- read.csv('./data/TechnicalValidation/FinalRaster_FreqPixelsUnresolvedConflict.csv')


length(unique(unresolved_conflicts$FIPS[unresolved_conflicts$PctCounty < 0.4]))/length(unique(unresolved_conflicts$FIPS))
length(unique(unresolved_conflicts$FIPS[unresolved_conflicts$PctCounty > 4.55]))

# summarize accuracy data too 

# national weighted average
accuracy <- readRDS('./data/TechnicalValidation/summarized_accuracy_data_CDL_NVC_Merged.rds')

national_accuracy <- accuracy %>% group_by(Dataset_Name) %>%
  dplyr::mutate(RelArea = NCells_County/sum(NCells_County), temp=WtdUserAcc*RelArea) %>%
  dplyr::summarise(WtdUserAcc = sum(temp))
  



