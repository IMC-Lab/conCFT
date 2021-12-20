# Makes text files to batch create sessionFiles for PLS
library(tidyverse)
# set global params
## values we're going to iterate over
subID = c('01','02','03','04','05','07','08','09','10','11','12','15',
          '16','17','18','20','21','22','23','24','25','26','27','28','29',
          '30','31','32','33','34','35','36')
runValues = c('1','2','3','4')

## make big dataframe for all subs & runs in session 2
session2_data = list.files('behavData/session2', full.names = TRUE, pattern='conCFT_s.*.csv', recursive = TRUE)
session2_data = do.call(rbind, lapply(session2_data, function(x) { read.csv(x, header = TRUE)[1:33]} ))
session2_data <- session2_data %>%
  rename(subID = sub) %>%
  mutate_at(c('fixOnsetTime', 'memOnsetTime', 'memRTtime', 'cftOnsetTime',
              'plausibilityOnsetTime', 'controlOnsetTime', 'difficultyOnsetTime', 'trialEnd'), function(x){(x-8)}) %>% # subtract 8s from onsets
  mutate(condition = factor(condition, levels=c(1,2), labels=c('Self', 'Context')), # convert onset times to TRs
         fixOnsetTR = round(fixOnsetTime / 2),
         memOnsetTR = round(memOnsetTime / 2),
         cftOnsetTR = round(cftOnsetTime / 2),
         plausibilityOnsetTR = round(plausibilityOnsetTime / 2),
         controlOnsetTR = round(controlOnsetTime / 2),
         difficultyOnsetTR = round(difficultyOnsetTime / 2),
         trialEndTR = round(trialEnd / 2),
         subID = ifelse(grepl("^[0-9]$", as.character(subID)), paste0('0', as.character(subID)), paste0('', as.character(subID))))

## values going into the text file
brain_region = 0.15 #threshold for parcellation
win_size = 4 + 1 #number of TRs to include in the temporal window. CFT + 1
across_run = 1 #merge data across runs for each participant
single_subj = 0 #we want to do group analysis, not single subject

## first 2/3 of the text file
text = c('brain_region', '\t', brain_region,'\n',
         'win_size', '\t', win_size,'\n',
         'across_run', '\t', across_run,'\n',
         'single_subj', '\t', single_subj,'\n\n',
         '%%% General section end %%%','\n',
         '%------------------------%','\n',
         '%%% Condition section start %%%','\n\n',
         'cond_name', '\t', 'Self','\n',
         'ref_scan_onset', '\t', '0','\n',
         'num_ref_scan', '\t', '1', '\n\n',
         'cond_name', '\t', 'Context','\n',
         'ref_scan_onset', '\t', '0','\n',
         'num_ref_scan', '\t', '1','\n\n',
         '%%% Condition section end %%%','\n',
         '%------------------------%','\n',
         '%%% Run section start %%%')

data <- session2_data %>%
  select(subID, run, condition, cftOnsetTR)

## make text files for each subject
for (subj in subID) {
  textFile <- file(paste('datamats/s', subj, '_timingFile.txt',sep=''), 'w') 
  writeLines(c('%%% General section start%%%', '\n',
               'prefix', '\t', paste0('conCFT_s',subj, '_CFT_only'), '\n'), sep='', con=textFile)
  writeLines(text, sep='',con=textFile) # add in text that's the same across subjects
  # initialize the for loop that populates each run with event onsets
  for (r in runValues) {
    contextOnsets <- data %>% filter(subID==subj, run==as.integer(r), condition=='Context') %>% pull(cftOnsetTR)
    selfOnsets <- data %>% filter(subID==subj, run==as.integer(r), condition=='Self') %>% pull(cftOnsetTR)
    writeLines(c('\n\n', 'data_files', '\t',
                 paste0('../conCFT_funcData/sub-', subj, '/sub-', subj, '_ses-day2_task-conCFT_run-', r,
                        '_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold_tempfilt_brain.nii'),
                 '\n'), sep='', con=textFile)
    writeLines(c('event_onsets', selfOnsets, '% selfCFT onsets'), sep='\t', con=textFile)
    writeLines(c('\n'), sep='', con=textFile)
    writeLines(c('event_onsets', contextOnsets, '% contextCFT onsets'), sep='\t', con=textFile)
    print(paste('sub:', subj, 'run:',r)) # write the rest of the text file
  }
  close(textFile)
}
