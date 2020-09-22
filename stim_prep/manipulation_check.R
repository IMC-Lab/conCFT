# quick n breezy manipulation check now that we have n > 1 subject
library(dplyr)
library(ggplot2)
library(ordinal)
library(ggpubr)

# load & prep data
pilot_data = list.files('../Data/Behav', full.names = TRUE, pattern='conCFT_s.*.csv', recursive = TRUE)
pilot_data = do.call(rbind, lapply(pilot_data, function(x) { read.csv(x, header = TRUE)} ))
pilot_data$sub <- as.factor(pilot_data$sub)
pilot_data$condition <- as.factor(pilot_data$condition)

manipulation_check <- clm(as.factor(controlResponse) ~ condition, data=pilot_data)
summary(manipulation_check)

ggplot(pilot_data, aes(x=condition, y=controlResponse, fill=sub)) +
  geom_violin() +
  stat_summary(fun.data = mean_se, geom = 'pointrange', color='black', position=position_dodge(0.9)) +
  scale_x_discrete(labels=c('self', 'context')) +
  ylab('Control (4=full control)') +
  theme_pubr(legend = 'right')
ggsave('conCFT_pilotresults.png', dpi=600)
