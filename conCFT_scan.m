function conCFT_scan
% Maria Khoudary (adapted from Leonard Faul's eCFT_S2 script)
% 1/29/2020 
% sub -   if single digits, start with 0
% run -     1, 2, 3, or 4 - included in output file

% The script can currently start by pressing the spacebar (after loading the first screen).

% When at the scanner, we want it to wait for a TTL pulse from the scanner to start.
% Look at lines 35, 199

% Clear Matlab window:
clc;

% Get user input for variables
subID = input('Subject number: ');
run = input('Run number: ');
practice = input('Practice?: ');

% Make sure we can find PsychToolbox at BIAC. Might need to adjust with recent updates.
if practice == 0
    if run == 1
     addpath('P:\MATLAB\PsychToolbox\3.0.11');
     BIACSetupPsychtoolbox;
    end
end

% reset the random seed
  rng shuffle;

% check for OpenGL compatibility, abort otherwise:
AssertOpenGL;

% Make sure we can connect to the daq (to get trigger)
if practice == 0
    try
       daq = DaqDeviceIndex();
    catch
       error('Daq device not found');
    end
end

% Make sure keyboard mapping is the same on all supported operating systems Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');

% Initialize keyboard responses (see below for mapping from keyboard to button box at BIAC)
% Button boxes:	O O O O     O O O O 
%       output: 9 8 7 6     1 2 3 4
%   	coding: - 1 2 3     4 5 6 7

% THIS IS MAPPING FOR BUTTON BOX
% this experiment only uses the right button box
%image = KbName('1!');
%rateMap = {'4', '5', '6', '7'};
%rate4 = KbName('1!');
%rate5 = KbName('2@');
%rate6 = KbName('3#');
%rate7 = KbName('4$');

% Use this mapping if you want to just use a normal keyboard for testing
% oddEvenFix is still setup for scanner, though.
% REMEMBER TO CHANGE!
image = KbName('1!'); %the key they press when they start imagining the CFT
% rateMap = {'1', '2', '3', '4'};
rate1 = KbName('1!'); 
rate2 = KbName('2@');
rate3 = KbName('3#');
rate4 = KbName('4$');

% Define conditions (e.g. 1 = Self-Based counterfactual, 2 = Context-Based CFT)
conditionText = {'Self', 'Context'};


%% file handling %%
sID = ['s', num2str(subID)];
folderName = [sID, '/results'];
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

% Define filenames of output and input files. Each run writes a new file.
dataFileName = [folderName, '/conCFT_', sID, '_run', num2str(run), '.csv']; 

% IMPORTANT!
% This script assumes that stimuli & their condition assignment are already (pesudo)randomized in the input file
stimulusFileName = [sID, '/conCFT_memlist_final_', sID, '.csv']; % stim list

% Read in the stimuli. 
% The text file contains the titles of each of the 64/80 memories provided by the participant during session 1 that we'll use as memory cues
stimulusFile = readtable(stimulusFileName);
eventTitles = stimulusFile.Title;
eventNum = stimulusFile.EventNumber;
condition = stimulusFile.Condition;

% For this experiment, we only want 16 memories per run. 
% This gives you a 16x1 cell array of stimuli you want(1-16, 17-32, 33-48, or 49-64, depending on the run)

memcue = eventTitles((run*16 - 15):(run*16)); 
eventNum = eventNum((run*16 - 15):(run*16));
condList = condition((run*16 - 15):(run*16));

% During the first run, check for existing data file with the same filename to prevent accidentally overwriting previous files 
% (except for subject numbers > 99 for testing purposes)
if subID < 99 && fopen(dataFileName, 'rt') ~= -1
    fclose('all');
    error('Data file already exists. Choose a different subject number.');
end

%% Psychtoolbox Setup %%
try
    
    % make variable for farthest screen (stimulation screen; what the participant sees in the scanner)
    screens = Screen('Screens');
    screenNumber = max(screens);
    
    % hide the mouse cursor:
    HideCursor;
    
    % If running on mac, go ahead and skip the sync tests (can comment out for windows)
    %Screen('Preference','SkipSyncTests', 1);
    
    % Open a double buffered fullscreen window on the stimulation screen ('screenNumber;) and choose/draw a black background. 
    % 'w' is the handle used to direct all drawing commands to that window (i.e., is the pointer to that window)
    % '~' is MATLAB syntax saying that we don't care to store the value of whatever is returned in that position
    [w, ~] = Screen('OpenWindow', screenNumber, 0);
    
    % Set text size (Most Screen functions must be called after opening an onscreen window, as they only take window handles 'w' as input):
    Screen('TextSize', w, 40);
    Screen('TextFont', w, 'Arial');

    % Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure they are loaded and ready when we need them - without delays in the wrong moment:
    [~, ~, keyCode] = KbCheck; %
    WaitSecs(0.1);
    GetSecs;
    
    % Set priority for script execution to realtime priority:
    Priority(MaxPriority(w));
    
    % Define variable lengths for experiment
    if practice == 0
        durationMem = 6.000;
        durationCFT = 8.000;
        durationRate = 4.000;
    elseif practice == 1
        durationMem = 2.000;
        durationCFT = 2.000;
        durationRate = 2.000;
    end
    
    % Jitter2 is the length of the active jitter task 
    jitter1 = Shuffle(repelem([0.750, 1.500], 16)); % 16 = number of trials per run
    jitter2 = Shuffle(repelem([3.000, 4.500], 16));
    jitter3 = Shuffle(repelem([0.750, 1.500], 16));
    
    % read rating images into matlab matrix
    plausibility = imread('task/Ratings/plausibilityScreen.jpg');
    control = imread('task/Ratings/controlScreen.jpg');
    difficulty = imread('task/Ratings/difficultyScreen.jpg');
    
%% Sync start of run with scanner trigger %%
    
    % Get the participant ready to go via intercom
    % Write instruction message for subject, nicely centered in the middle of the display, in white color:
    message = 'The experiment is about to begin';
    DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    
    % Get the current count for the daq
    if practice == 0
        curcount = DaqCIn(daq);
    end
    
    % Update the display to show the instruction text:
    Screen('Flip', w);
    
    % Wait for TTL pulse to officially start
    while 1     % This will need a TTL pulse to continue
         if  practice == 0 && DaqCIn(daq) > curcount 
             % start your task
             break            
         else % or use space to start
            [~,~,c] = KbCheck;
            press = KbName(c);
            if (strcmp(press, 'space') == 1)
                break
            end
           pause(.05) % do short sleep here just so you are not executing the counter check a billion times
         end
    end

%% Initialize task %%

    BeginEx = GetSecs; % get the time at which we move on
    
    % IMPORTANT! The first 4 TRs will be discarded. BIAC can do this for you automatically.
    message = 'Relax';
    DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    Screen('Flip', w);
    if practice == 0
        WaitSecs(8.000);
    elseif practice == 1
        WaitSecs(2.000);
    end
    
    % Get fixation screen ready to go
    message = '+';
    DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    
    % open ASCII (.txt) file and append
    datafilepointer = fopen(dataFileName, 'wt+'); 
    
    % What is gonna get saved to the output file? 
    %(... means that code continues onto the next line -- helps with readability)
    fprintf(datafilepointer, ...
        '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s', ...
        'sub', 'run', 'trial', 'condition',...
        'fixOnsetTime', 'jitter1', 'jitter2', 'jitter3', 'jitterStim1', 'jitterStim2', 'jitterStim3', 'jitterResp', 'jitterAccuracy',... 
        'memOnsetTime', 'eventNum', 'eventTitle', 'memRTtime', 'memRT',... 
        'cftOnsetTime', 'endCFT',...
        'plausibilityOrder', 'plausibilityOnsetTime', 'plausibilityResponse', 'plausibilityRT', ...
        'controlOrder', 'controlOnsetTime', 'controlResponse', 'controlRT',...
        'difficultyOrder', 'difficultyOnsetTime', 'difficultyResponse', 'difficultyRT',...
        'trialEnd');
    
if practice == 0
    runLength = 16;
elseif practice == 1
    runLength = 1;
end

%% start trials %%
    for trial = 1:runLength
        
        % initialize memRT and cftRT
        memRT = [];
        
        % load memory title for the cue and draw it to the back buffer
        cue = memcue{trial};
        
        % fixation with normal crosshair (message should still be +)
        DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
        time1 = Screen('Flip', w);
        fixOnsetTime = time1 - BeginEx;
        WaitSecs(jitter1(trial));
        
        % odd even task for the rest of the fixation
        [jitterStim, jitterResp, jitterAccuracy] = orientationFix(jitter2(trial), w, practice); 
        if size(jitterStim, 2) == 2
            jitterStim{end+1} = NaN;
        end
        
        %fixation after odd/even task
        Screen('TextSize', w, 40);
        DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
        Screen('Flip', w);
        WaitSecs(jitter3(trial));
            
        % Show stimulus on screen at next possible display refresh cycle
        Screen('TextSize', w, 40);
        DrawFormattedText(w,[cue,'\n\n\n'],'center', 'center', WhiteIndex(w));
            
        % Store the estimated system time at which the stimulus is displayed
        [~, time2] = Screen('Flip', w);
        memOnsetTime = time2 - BeginEx;
            
        % Keep the cue up for 'durationMem' length of time
        while (GetSecs - time2) <= durationMem
            [keyIsDown, memPress, ~] = KbCheck;
            if keyIsDown == 1
                memRT = memPress - time2;
            end
        end
        
        % Store absolute timing of memory recall onset
        memRTtime = memRT + memOnsetTime;
            
        % Add CFT condition to stim screen at next possible display refresh cycle
        Screen('TextSize', w, 40)
        DrawFormattedText(w, [cue, '\n\n\n', conditionText{condList(trial)}], 'center', 'center', WhiteIndex(w));
             
       % Store the estimated system time at which the stimulus is displayed
        [~, time3] = Screen('Flip', w);
        cftOnsetTime = time3 - BeginEx;
            
       % Keep the cue up for 'durationCFT' length of time
       % When the participant clicks a button (started imagining target CFT) then record the response time. Can easily make it so only the first response is recorded by adding a conditional.
        while (GetSecs - time3) <= durationCFT
        end
        
        
        % Close all offscreen textures so they don't build up
        Screen('Close');
        
        % Randomly assign presentation of rating scales 
        ratingsOrder = Shuffle(repelem([1,2,3],1));
        
        % Cycle through all 3 rating scales 
            for RatingNum = 1:3
                ratingRT = []; 
                ratingResp = [];
                
                % separate scales by a fixation cross
                DrawFormattedText(w, '+', 'center', 'center', WhiteIndex(w));
                
                % if this is the first rating in the trial, go ahead and record when imagination ends and the fixation starts. 
                if RatingNum == 1
                    [~, time4] = Screen('Flip', w);
                    endCFT = time4 - BeginEx;
                    WaitSecs(0.500);
                else
                    Screen('Flip', w); 
                    WaitSecs(0.500);
                end
                
               % define rating scale based on RatingOrder
                if ratingsOrder(RatingNum) == 1
                    tex = Screen('MakeTexture', w, plausibility); % make texture image out of matrix
                    response_image = 'plausibility';
                elseif ratingsOrder(RatingNum) == 2
                    tex = Screen('MakeTexture', w, control);
                    response_image = 'control';
                elseif ratingsOrder(RatingNum) == 3
                    tex = Screen('MakeTexture', w, difficulty);
                    response_image = 'difficulty';
                end    
        
                % load into buffer
                Screen('DrawTexture', w, tex);
                
                % display at next possible display refresh cycle & store onset time
                [~, time5] = Screen('Flip', w);
                ratingOnsetTime = time5 - BeginEx;
                
                % keep the rating up for 'durationRate' length of time and continuously check for valid responses
                while (GetSecs - time5) <= durationRate
                    [~, ratingPress, keyCode] = KbCheck;
            
                % if there's a valid response, record it along with RT
                    if ( keyCode(rate1) || keyCode(rate2) || keyCode(rate3) || keyCode(rate4) )
             
                % convert the code to a string indicating what the subject pressed
                    keyName = KbName(keyCode);
                % if >1 keys were presed simultaneously, reduce to first key press. 
                        % a number and letter will yield a number, 2 numbers will yield the smaller number
                    if iscell(keyName)
                        keyName = keyName{1};
                    end
                
                 % convert button press response to output we expect
                        ratingResp = keyName(1);
                
                 % change screen to reflect button response by loading in appropriate response image
                 if ratingResp ~= ' '
                        ratingScreen = imread(['task/Ratings/', response_image, ratingResp, '.jpg']);
                        ratingTex = Screen('MakeTexture', w, ratingScreen);
                        Screen('DrawTexture', w, ratingTex);
                        Screen('Flip', w);
                 end
                % calculate and store response time
                        ratingRT = ratingPress - ratingOnsetTime;
                    end
                end
        
                % Close all offscreen textures so they don't build up
                Screen('Close');
                
                % Save the response based on the rating shown
                if ratingsOrder(RatingNum) == 1
                    plausibilityOrder = RatingNum;
                    plausibilityOnsetTime = ratingOnsetTime;
                    plausibilityResponse = ratingResp;
                    plausibilityRT = ratingRT;
                elseif ratingsOrder(RatingNum) == 2
                    controlOrder = RatingNum;
                    controlOnsetTime = ratingOnsetTime;
                    controlResponse = ratingResp;
                    controlRT = ratingRT;
                elseif ratingsOrder(RatingNum) == 3
                    difficultyOrder = RatingNum;
                    difficultyOnsetTime = ratingOnsetTime;
                    difficultyResponse = ratingResp;
                    difficultyRT = ratingRT;
                end  
            end
       
        % Close all offscreen textures so they don't build up
        Screen('Close');
        
        % store trial end time
        [~, time6] = Screen('Flip', w);
        trialEnd = time6 - BeginEx;
        
        
        % Write trial result to file:  %2 %3 %4 %5 %6 %7 %8 %9 %10%     %13  %15       %18
        fprintf(datafilepointer, '\n%i,%i,%i,%i,%f,%f,%f,%f,%s,%s,%s,%s,%f,%f,%i,%s,%f,%f,%f,%f,%i,%f,%s,%f,%i,%f,%s,%f,%i,%f,%s,%f,%f', ...
                subID, run, trial, condList(trial),... %4
                fixOnsetTime, jitter1(trial), jitter2(trial), jitter3(trial), jitterStim{1}, jitterStim{2}, jitterStim{3}, mat2str(jitterResp), jitterAccuracy, ...%13
                memOnsetTime, eventNum(trial), cue, memRTtime, memRT,...%18
                cftOnsetTime, endCFT, ...%20
                plausibilityOrder, plausibilityOnsetTime, plausibilityResponse, plausibilityRT, ...%24
                controlOrder, controlOnsetTime, controlResponse, controlRT,...%28
                difficultyOrder, difficultyOnsetTime, difficultyResponse, difficultyRT,...%32
                trialEnd);%33
                
        % Get rid of all extra drawn textures
        Screen('Close');
    end
    
% Tell the participant this run is over
  message = 'This run is over.';
  DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    
% Update the display to show the concluding text:
  Screen('Flip', w);
    
% Stay up for 4 seconds:
  WaitSecs(4.000);
    
% Flip back to black screen and display the total runtime
  [~, EndTask] = Screen('Flip', w);
  RunTime = EndTask - BeginEx;
  disp(RunTime);
  
  %% resting state 
if practice == 0
    minutes = 7;
elseif practice == 1
    minutes = 1;
end

if run == 4
   DrawFormattedText(w, 'Beginning resting state scan...', 'center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(4.000);
   DrawFormattedText(w, 'Relax', 'center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(4.000);
   Screen('Flip', w);
   % display crosshair with TTL pulse
   while 1    
         if  practice == 0 && DaqCIn(daq) > curcount 
             break            
         else 
            [~,~,c] = KbCheck;
            press = KbName(c);
            if (strcmp(press, 'space') == 1)
                break
            end
           pause(.05) % do short sleep here just so you are not executing the counter check a billion times
         end
   end
   DrawFormattedText(w, '+', 'center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(60*minutes);
   Screen('Flip', w);
   WaitSecs(0.5000);
   DrawFormattedText(w, 'The experiment is now over.','center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(4.000);
end

% Cleanup at end of experiment: close window, show mouse cursor, close result file, switch Matlab/Octave back to priority 0 (normal priority):
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
    
% End of task:
return;

catch
% catch error: This is executed in case something goes wrong in the 'try' part due to programming error etc.:
% Do same cleanup as at the end of a regular session...
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
    
% Output the error message that describes the error:
  psychrethrow(psychlasterror);  
return;
    
end
end