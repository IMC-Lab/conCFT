## makes stimuli for scanning & post-study questionnaire
library(dplyr)
library(ltm)

# load in & tidy Session 1 file
subID = '2'
memlist <- read.csv(paste0('../../Stimuli/','s',subID,'/conCFT_Session 1_s', subID,'.csv'))[,1:10]
memlist <- memlist[2:nrow(memlist),]
memlist <- memlist[!is.na(memlist$Event.number),]
memlist <- memlist %>% mutate_at(vars(Detail:Control), as.integer)

# assess inter-rater reliability
original_alpha = cronbach.alpha(memlist[,9:10])[['alpha']]
memlist$difference <- abs(memlist[,9] - memlist[,10])
# write csv highlighting points of difference
memlist <- memlist[order(memlist$difference, decreasing = TRUE),]
write.csv(memlist, file=paste0('../Stimuli/','s',subID,'/memlist_disagreement.csv'), row.names=FALSE)

# calculate new alpha based on updated ratings -- repeat until alpha surpasses threshold 
memlist_final <- read.csv(paste0('../Stimuli/','s',subID,'/memlist_disagreement_updated','.csv'))[,1:10]
final_alpha = cronbach.alpha(memlist_final[,9:10])[['alpha']] # new alpha

# make memlist_final
memlist_final$rating <- rowMeans(memlist_final[,9:10]) 
memlist_final <- memlist_final %>% arrange(desc(rating), Valence)
memlist_final <- memlist_final[1:67,] #keep an extra 3 memories for pre-scan practice
valence = mean(memlist_final$Valence, na.rm=T)

# randomize memory order
set.seed(45)
randrows <- sample(nrow(memlist_final))
memlist_final <- memlist_final[randrows, ]

# generate pseudorandom condition column
randomConditions <- function (length=8, repetitions=3) {
  conditions <- rep(c(1,2), each=length)
  while (max(rle(conditions)$lengths) > repetitions)
    conditions <- sample(conditions)
  return(conditions)
}

condList <- c(randomConditions(), randomConditions(), 
              randomConditions(), randomConditions(), 0, 0, 0)

memlist_final$Condition <- condList
write.csv(memlist_final, file=paste0('../../Stimuli/','s',subID,'/memlist_final_s', subID, '.csv'), row.names=FALSE)

# write post-scan questionnaire
psq <- memlist_final[1:64,] %>% dplyr::select(Title, Condition)

i = 0
for (c in psq$Condition) {
  i = i + 1
  if (c == 1) {
    psq$Condition[i] = 'Self'
  }
  else
    psq$Condition[i] = 'Context'
}

psq$Description <- ''
psq$Frequency <- ''

write.csv(psq, file=paste0('../../Stimuli/','s',subID,'/psq_s', subID, '.csv'), row.names=FALSE)
