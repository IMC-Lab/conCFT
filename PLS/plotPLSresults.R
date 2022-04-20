# Plot PLS results
library(tidyverse)
library(paletti)
library(patchwork)

## plotting colors
custom_colors <- c('#ffa200', '#00a6ff')   
custom_color <- get_scale_color(get_pal(custom_colors))
custom_fill <- get_scale_fill(get_pal(custom_colors))

## load in means
BSR <- read.csv('results/correctedMeanCentered_means.csv', F) %>% 
  rename(LV1=V1,LV2=V2) %>% 
  as.data.frame() %>%
  mutate(condition=c('Internal', 'External')) 
## load in upper CIs
BSR_upper <- read.csv('results/correctedMeanCentered_upperAdj.csv', F) %>% 
  rename(LV1_upper=V1,LV2_upper=V2) %>% 
  as.data.frame() %>%
  mutate(condition=c('Internal', 'External'))
## load in lower CIs
BSR_lower <- read.csv('results/correctedMeanCentered_lowerAdj.csv', F) %>% 
  rename(LV1_lower=V1,LV2_lower=V2) %>% 
  as.data.frame() %>% 
  mutate(condition=c('Internal', 'External'))
## make one dataframe for brain scores
BSR_LV1 <- BSR %>% dplyr::select(-LV2) 
BSR_LV1$upper <- BSR_upper$LV1_upper
BSR_LV1$lower <- BSR_lower$LV1_lower
## load in temporal brain scores
BSR_tbs <- read.csv('results/correctedMeanCentered_tbs.csv', F) %>%
  rename(Lag0=V1, Lag1=V2, Lag2=V3, Lag3=V4, Lag4=V5) %>%
  mutate(condition=c('Internal', 'External')) %>%
  pivot_longer(cols=c(Lag0:Lag4), names_to = 'Lag', values_to = 'brain_score')

## plot mean-centered brain scores
mcPlot <- ggplot(BSR_LV1, aes(y=LV1, x=condition, fill=condition)) +
  ylim(-20, 20) + 
  geom_hline(yintercept=0) + 
  geom_col(width=0.5) +
  geom_errorbar(aes(ymin=lower, ymax=upper),color='black', width=0.1) +
  theme_minimal() +
  custom_fill() +
  labs(y='Brain score', x='', title='') +
  theme(axis.text = element_text(size = 14, color='black'),
        axis.text.x = element_text(size=16),
        axis.title = element_text(size = 14),
        legend.position = 'none')

## plot temporal brain scores
tbsPlot <- ggplot(BSR_tbs, aes(y=brain_score,x=Lag,group=condition, color=condition,fill=condition)) +
  geom_hline(yintercept=0) + 
  geom_line(size=2) +
  scale_x_discrete(labels=c('TR1', 'TR2', 'TR3', 'TR4', 'TR5')) + 
  labs(y='Temporal brain score', x='', title='', color='Condition') +
  theme_minimal() + 
  custom_color() + 
  theme(axis.text = element_text(size = 14, color='black'),
        axis.text.x = element_text(size=16),
        axis.title = element_text(size = 14),
        legend.text = element_text(size=12),
        legend.title=element_text(size=14),
        legend.position = 'none')

## export as 1 figure
mcPlot + tbsPlot
ggsave('../figures/meanCentered.jpeg', height=4, width=8, dpi='retina')

