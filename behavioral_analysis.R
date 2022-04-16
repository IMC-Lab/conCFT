# load packages -----------------------------------------------------------
library(lme4)
library(lmerTest)
library(emmeans)
library(ltm) #to compute cronbachs alpha
library(sjPlot)
library(patchwork)
library(paletti)
library(tidyverse)

# load data ---------------------------------------------------------------
## session 1 data
session1_data = list.files('behavData/session1', full.names = TRUE, pattern='memlist_final_s.*.csv', recursive = TRUE)
session1_data = do.call(rbind, lapply(session1_data, function(x) { read.csv(x, header = TRUE)} ))
session1_data <- session1_data %>%
  rename(subID = sub, eventNum = EventNumber, condition=Condition, eventTitle=Title) %>%
  mutate(condition=factor(condition, levels=c(0,1,2), labels=c('Practice', 'Internal', 'External'))) %>%
  filter(condition != 'Practice')

## load in session 2 data
session2_data = list.files('behavData/session2', full.names = TRUE, pattern='conCFT_s.*.csv', recursive = TRUE)
session2_data = do.call(rbind, lapply(session2_data, function(x) { read.csv(x, header = TRUE)[1:33]} ))
session2_data <- session2_data %>%
  rename(subID = sub) %>%
  mutate(condition = factor(condition, levels=c(1,2), labels=c('Internal', 'External')))

## load in post-study questionnaire (psq)
psq_data = list.files('behavData/session1', full.names = TRUE, pattern='psq_s.*.csv', recursive = TRUE)
psq_data = do.call(rbind, lapply(psq_data, function(x) { read.csv(x, header = TRUE)} ))
psq_data <- psq_data %>%
  rename(subID = sub,
         condition = Condition,
         eventTitle = Title) %>%
  mutate(condition=factor(condition, levels=c('Self','Context'), labels=c('Internal', 'External')))


# tidy data ---------------------------------------------------------------
## first create subset of psq_data so that we can add frequency to the main df
psq <- psq_data %>%
  filter(subID %in% session2_data$subID) %>% 
  dplyr::select(eventTitle, condition, subID, Frequency)

## then get rid of subjects who didn't get scanned, drop memories used for practice, and fix behavioral responses >7
all_data <- session1_data %>% 
  filter(subID %in% session2_data$subID) %>%
  right_join(session2_data, by=c('subID', 'eventNum', 'condition', 'eventTitle'))  %>%
  left_join(psq, by=c('eventTitle', 'condition', 'subID')) %>%
  mutate(Control=ifelse(Control>7, 7, Control),
         Regret=ifelse(Regret>7, 7, Regret),
         Valence=ifelse(Valence>7, 7, Valence),
         Vividness=ifelse(Vividness>7, 7, Vividness),
         Frequency=ifelse(Frequency>7, 7, Frequency),
         condition=factor(condition))

## write csv for easy access in other analyses
# write.csv(all_data, 'behavData/all_data.csv')


# make custom color palette & summary stat plotting function -----------------------------------------------
custom_colors <- c('#00a6ff', '#ffa200')   
custom_color <- get_scale_color(get_pal(custom_colors))
custom_fill <- get_scale_fill(get_pal(custom_colors))

mean_sd <- function(x) {
  m <- mean(x)
  ymin <- m-sd(x)
  ymax <- m+sd(x)
  return(c(y=m,ymin=ymin,ymax=ymax))
}



# summary statistics for session 1 ----------------------------------------

## compute cronbach's alpha for full set of memories
memlist_disagreement = list.files('behavData/session1', full.names = TRUE, pattern='memlist_disagreement.*.csv', recursive = TRUE)
memlist_disagreement = do.call(rbind, lapply(memlist_disagreement, function(x) { read.csv(x, header = TRUE)} ))
disagreement_extras <- session1_data %>% filter(subID==2 | subID==24) %>% #add in subjects who didn't have a memlist disagreement csv
  rename(EventNumber=eventNum,
         Title=eventTitle) %>%
  dplyr::select(-c(condition, subID, rating))
initial_alpha <- memlist_disagreement %>%
  dplyr::select(-difference) %>%
  rbind(., disagreement_extras)
full_alpha <- cronbach.alpha(initial_alpha[9:10])[['alpha']]

## compute cronbach's alpha for final set of memories
final_alpha <- cronbach.alpha(all_data[9:10])[['alpha']]

## make long dataframe
session1_long <- all_data %>%
  dplyr::select(Detail, Vividness, Valence, Regret, Control) %>%
  pivot_longer(c(Detail, Vividness, Valence, Regret, Control), names_to = 'memory_characteristic', values_to = 'rating') %>%
  mutate(rating=ifelse(rating==8, 7, rating))

## plot 
session1_plot <- function(aes_DV, DV, title) {
  ggplot(all_data, aes_(aes_DV)) +
    geom_bar(color='black', fill='#57C09B', width=1, alpha=1) + 
    geom_vline(aes(xintercept=mean({{DV}},na.rm=T)), size=0.75, linetype='dashed', color='gray30') +
    geom_errorbarh(aes(xmin=mean({{DV}},na.rm=T)-sd({{DV}},na.rm=T), xmax=mean({{DV}}, na.rm=T)+sd({{DV}}, na.rm=T), y=0, height=50), size=1) + 
    geom_point(aes(x=mean({{DV}}, na.rm=T), y=0), size=3) + 
    scale_x_continuous(breaks=1:7) + 
    labs(y='Count', x='Rating', title=title) + 
    theme_light() + 
    theme(legend.position = 'none',
          axis.text.x=element_text(size=10, color='black'),
          axis.text.y=element_text(size=10, color='black'),
          axis.title = element_text(size=12),
          plot.title=element_text(size=16, hjust=0.5, face='bold'))
}

controlHist <- session1_plot(~Control, Control, 'Control')
detailHist <- session1_plot(~Detail, Detail, 'Detail')
regretHist <- session1_plot(~Regret, Regret, 'Regret')
valenceHist <- session1_plot(~Valence, Valence, 'Valence') 
vividnessHist <- session1_plot(~Vividness, Vividness, 'Vividness')
controlHist + detailHist + regretHist + valenceHist + vividnessHist
ggsave('suppFigures/memoryCharacteristics.jpeg', width=10, dpi='retina')


## write summary stat table
session1_summary <- all_data %>%
  summarise(controlMean=mean(Control, na.rm=T),
            controlSD=sd(Control, na.rm=T),
            detailMean=mean(Detail, na.rm=T),
            detailSD=sd(Detail, na.rm=T),
            regretMean=mean(Regret, na.rm=T),
            regretSD=sd(Regret, na.rm=T),
            valenceMean=mean(Valence, na.rm=T),
            valenceSD=sd(Valence, na.rm=T),
            vividnessMean=mean(Vividness, na.rm=T),
            vividnessSD=sd(Vividness, na.rm=T)) %>%
  mutate_if(is.numeric, ~round(.,2)) %>%
  pivot_longer(cols = controlMean:vividnessSD, names_to = 'summary_stat', values_to = 'value')
write.csv(session1_summary, 'suppFigures/session1_summary.csv')



# summary statistics for session 2 -------------------------------------------------
## compute memory button press summary stats stats
memRTmean <- mean(all_data$memRT, na.rm=T)
memRTsd <- sd(all_data$memRT, na.rm=T)

## write table with summary stats for session2 variables
session2_summary <- all_data %>%
  dplyr::select(condition, plausibilityResponse, controlResponse, difficultyResponse, Frequency) %>%
  group_by(condition) %>%
  summarise(plausibilityMean=mean(plausibilityResponse, na.rm=T),
            plausibilitySD=sd(plausibilityResponse, na.rm=T),
            controlMean=mean(controlResponse, na.rm=T),
            controlSD=sd(controlResponse, na.rm=T),
            difficultyMean=mean(difficultyResponse, na.rm=T),
            difficultySD=sd(difficultyResponse, na.rm=T),
            frequencyMean=mean(Frequency, na.rm=T),
            frequencySD=sd(Frequency, na.rm = T)) %>%
  mutate_if(is.numeric, ~round(., 2)) %>%
  pivot_longer(cols=plausibilityMean:frequencySD, names_to='summary_stat', values_to='value')
write.csv(session2_summary, 'suppFigures/session2_summary.csv')

summary_stat <- session2_summary %>%
  pivot_wider(names_from = summary_stat)

## plot
session2_plot <- function(aes_DV, DV, title, n) {
  ggplot(all_data, aes_(x=aes_DV, fill=~condition)) +
    facet_wrap(vars(condition)) + 
    geom_bar(color='black', width=1, alpha=1) + 
    geom_errorbarh(data=filter(all_data, condition=='Internal'), aes(xmin=mean({{DV}},na.rm=T)-sd({{DV}},na.rm=T), xmax=mean({{DV}}, na.rm=T)+sd({{DV}}, na.rm=T), y=0, height=50), size=1) +
    geom_errorbarh(data=filter(all_data, condition=='External'),  aes(xmin=mean({{DV}},na.rm=T)-sd({{DV}},na.rm=T), xmax=mean({{DV}}, na.rm=T)+sd({{DV}}, na.rm=T), y=0, height=50), size=1) +
    geom_point(data=filter(all_data, condition=='Internal'), aes(x=mean({{DV}},na.rm=T), y=0), size=3) +
    geom_point(data=filter(all_data, condition=='External'), aes(x=mean({{DV}},na.rm=T), y=0), size=3) +
    geom_vline(data=filter(all_data, condition=='Internal'), aes(xintercept=mean({{DV}},na.rm=T)), size=0.75, linetype='dashed', color='gray30') +
    geom_vline(data=filter(all_data, condition=='External'), aes(xintercept=mean({{DV}},na.rm=T)), size=0.75, linetype='dashed', color='gray30') +
    scale_x_continuous(breaks=1:n) + 
    custom_fill() +
    labs(y='Count', x='Rating', title=title) + 
    theme_light() + 
    theme(legend.position = 'none',
          strip.background = element_rect(fill='gray90'),
          strip.text = element_text(color='black', size=14),
          axis.text.x=element_text(size=10, color='black'),
          axis.text.y=element_text(size=10, color='black'),
          axis.title = element_text(size=12),
          plot.title=element_text(size=16, hjust=0.5, face='bold'))
}

controlHist2 <- session2_plot(~controlResponse, controlResponse, 'Perceived control over eCFT', 4)
difficultyHist <- session2_plot(~difficultyResponse, difficultyResponse, 'Difficulty of eCFT generation', 4)
plausibilityHist <- session2_plot(~plausibilityResponse, plausibilityResponse, 'Perceived plausibility of eCFT', 4)
frequencyHist <- session2_plot(~Frequency, Frequency, 'Frequency of eCFT generation', 7)
controlHist2 + difficultyHist + plausibilityHist + frequencyHist + plot_layout(nrow=4)
ggsave('suppFigures/eCFTCharacteristics.jpeg', width=10, height=10, dpi='retina')

# fit linear mixed effects models ---------------------------------------------

## perceived control
controlModel <- lmer(controlResponse ~ condition + (1+condition|subID), all_data)
## write summary table
tab_model(controlModel,
          file='figures/table_controlModel.html',
          show.df = T,
          p.val='satterthwaite',
          strings=c(stat='Beta estimate', ci='CI (95%)', p='p value'),
          dv.labels = 'Perceived control over eCFT',
          col.order = c('est','ci','df.error','stat','p'),
          pred.labels=c('Intercept', 'Condition (External)'))

## difficulty
difficultyModel <- lmer(difficultyResponse ~ condition + (1+condition|subID), all_data)
## write summary table
tab_model(difficultyModel,
          file='figures/table_difficultyModel.html',
          show.df = T,
          p.val='satterthwaite',
          strings=c(stat='Beta estimate', ci='CI (95%)', p='p value'),
          dv.labels = 'Difficulty of eCFT generation',
          col.order = c('est','ci','df.error','stat','p'),
          pred.labels=c('Intercept', 'Condition (External)'))

## plausibility
plausibilityModel <- lmer(plausibilityResponse ~ condition + (1+condition|subID), all_data)
## write summary table
tab_model(plausibilityModel,
          file='figures/table_plausibilityModel.html',
          show.df = T,
          p.val='satterthwaite',
          strings=c(stat='Beta estimate', ci='CI (95%)', p='p value'),
          dv.labels = 'Perceived plausibility of eCFT',
          col.order = c('est','ci','df.error','stat','p'),
          pred.labels=c('Intercept', 'Condition (External)'))

## frequency
frequencyModel <- lmer(Frequency ~ condition + (1+condition|subID), all_data)
tab_model(frequencyModel,
          file='suppFigures/table_frequencyModel.html',
          show.df = T,
          p.val='satterthwaite',
          strings=c(stat='Beta estimate', ci='CI (95%)', p='p value'),
          dv.labels = 'Rumination on eCFT (measured as frequency of imagination',
          col.order = c('est','ci','df.error','stat','p'),
          pred.labels=c('Intercept', 'Condition (External)'))

# plot model results ------------------------------------------------------
modelPlot <- function(model, raw_y, ylab, title) {
  emmeans(model, ~ condition) %>%
    as.data.frame() %>%
    ggplot(aes(x=condition, y=emmean, fill=condition)) +
    theme_light() +
    geom_violin(aes_(y=raw_y), data=all_data, bw=0.4) +
    geom_pointrange(aes(ymin=lower.CL, ymax=upper.CL), size=0.8) + 
    custom_fill() + 
    labs(y=ylab, x=NULL, title=title) +
    theme(text = element_text(size=14, color='black'),
          plot.title = element_text(hjust=0.5, face='bold'),
          axis.text.x = element_text(size=16),
          legend.position = 'none')
}

controlPlot <- modelPlot(controlModel, ~controlResponse, 'Perceived control', 'Control model')
ggsave('suppFigures/controlPlot.jpeg', width=8, dpi='retina')

difficultyPlot <- modelPlot(difficultyModel, ~difficultyResponse, 'Difficulty of generation', 'Difficulty model')
ggsave('suppFigures/difficultyPlot.jpeg', width=8, dpi='retina')  

plausibilityPlot <- modelPlot(plausibilityModel, ~plausibilityResponse, 'Perceived plausibility', 'Plausibility model')
ggsave('suppFigures/plausibilityPlot.jpeg', width=8, dpi='retina') 

frequencyPlot <- modelPlot(frequencyModel, ~Frequency, 'Frequency of imagination', 'Frequency model') + 
  scale_y_continuous(breaks=c(1:7))
ggsave('suppFigures/frequencyPlot.jpeg', width=8, dpi='retina') 

difficultyPlot + controlPlot + plausibilityPlot + frequencyPlot + plot_layout(ncol=4)
ggsave('suppFigures/modelsPlot.jpeg', width=14, dpi='retina')