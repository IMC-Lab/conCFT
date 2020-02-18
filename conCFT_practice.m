function conCFT_practice
% Maria Khoudary (adapted from Leonard Faul's eCFT_S2 script)
% 2/13/2020
% sub -   if single digits, start with 0
% run -     1, 2, 3, or 4 - included in output file

% The script can currently start by pressing the spacebar (after loading the first screen).

% Clear Matlab window:
clc;

% Get user input for variables
subID = input('Subject number: ');
sID = ['s', num2str(subID)];

% reset the random seed
rng shuffle;

% check for OpenGL compatibility, abort otherwise:
AssertOpenGL;

% Make sure keyboard mapping is the same on all supported operating systems Apple MacOS/X, MS-Windows and GNU/Linux:
KbName('UnifyKeyNames');

% Use this mapping for testing
image = KbName('1!'); %the key they press when they start imagining the CFT
rate1 = KbName('1!'); 
rate2 = KbName('2@');
rate3 = KbName('3#');
rate4 = KbName('4$');


%% file handling %%

% Define filenames of output and input files. 
dataFileName = [sID, '/conCFT_','Session2_practice', '.csv']; 
stimulusFileName = [sID, '/conCFT_memlist_final_', sID, '.csv'];

% Read in the stimuli. 
stimulusFile = readtable(stimulusFileName);
eventTitles = stimulusFile.Title;
eventNum = stimulusFile.EventNumber;

% pull in the last 3 memories (those that won't be presented in the scanner)
memcue = eventTitles(65:67); 
eventNum = eventNum(65:67);

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
    durationMem = 1.000;
    durationCFT = 1.000;
    durationRate = 1.000;
    
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
    
    % Update the display to show the instruction text:
    Screen('Flip', w);
    
    % Wait for spacebar to officially start
    while 1     
            [~,~,c] = KbCheck;
            press = KbName(c);
            if (strcmp(press, 'space') == 1)
                break
            end
    end

%% Collect resting state data %%



%% Initialize task %%

    BeginEx = GetSecs; % get the time at which we move on from resting state acquisition
    
    % IMPORTANT! The first 4 TRs will be discarded. BIAC can do this for you automatically.
    message = 'Relax';
    DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    Screen('Flip', w);
    WaitSecs(1.000);
    
    % Get fixation screen ready to go
    message = '+';
    DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    
    % open ASCII (.txt) file and append
    datafilepointer = fopen(dataFileName, 'wt+'); 
    
    % What is gonna get saved to the output file? 
    %(... means that code continues onto the next line -- helps with readability)
    fprintf(datafilepointer, ...
        '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s', ...
        'sub', 'trial', 'condition',...
        'fixOnsetTime', 'jitter1', 'jitter2', 'jitter3', 'fixAccuracy',... 
        'memOnsetTime', 'eventNum', 'eventTitle', 'memRTtime', 'memRT',... 
        'cftOnsetTime', 'endCFT',...
        'ratingsOrder', ...
        'plausibilityOnsetTime', 'plausibilityResponse', 'plausibilityRT', ...
        'controlOnsetTime', 'controlResponse', 'controlRT',...
        'difficultyOnsetTime', 'difficultyResponse', 'difficultyRT',...
        'trialEnd');
    
%% start trials %%
for trial = 1:3
        
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
        fixAccuracy = orientationFix(jitter2(trial), w, 1); 
        
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
            [~, memPress, keyCode] = KbCheck;
            if keyCode(image)
                memRT = memPress - time2;
            end
        end
        
        % Store absolute timing of memory recall onset
        memRTtime = memRT + memOnsetTime;
            
        % Add CFT condition to stim screen at next possible display refresh cycle
        Screen('TextSize', w, 40)
        if trial == 1 || trial == 3
            condition = 'Context';
            DrawFormattedText(w, [cue, '\n\n\n', condition], 'center', 'center', WhiteIndex(w));
        else
            condition = 'Self';
            DrawFormattedText(w, [cue, '\n\n\n', condition], 'center', 'center', WhiteIndex(w));
        end
       % Store the estimated system time at which the stimulus is displayed
        [~, time3] = Screen('Flip', w);
        cftOnsetTime = time3 - BeginEx;     
      % Keep the cue up for 'durationCFT' length of time
        while (GetSecs - time3) <= durationCFT
        end 
        
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
                    plausibilityOnsetTime = ratingOnsetTime;
                    plausibilityResponse = ratingResp;
                    plausibilityRT = ratingRT;
                elseif ratingsOrder(RatingNum) == 2
                    controlOnsetTime = ratingOnsetTime;
                    controlResponse = ratingResp;
                    controlRT = ratingRT;
                elseif ratingsOrder(RatingNum) == 3
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
        
        % Write trial result to file:
        fprintf(datafilepointer, '\n%i,%i,%s,%f,%f,%f,%f,%f,%f,%s,%s,%f,%f,%f,%f,%s,%f,%s,%f,%f,%s,%f,%f,%s,%f,%f', ...
                subID, trial, condition,...
                fixOnsetTime, jitter1(trial), jitter2(trial), jitter3(trial), fixAccuracy, ...
                memOnsetTime, eventNum(trial), cue, memRTtime, memRT,...
                cftOnsetTime, endCFT, ...
                mat2str(ratingsOrder), ...
                plausibilityOnsetTime, plausibilityResponse, plausibilityRT, ...
                controlOnsetTime, controlResponse, controlRT,...
                difficultyOnsetTime, difficultyResponse, difficultyRT,...
                trialEnd);
                
        % Get rid of all extra drawn textures
        Screen('Close');
   while 1
    [~,~,c] = KbCheck;
    press = KbName(c);
    if (strcmp(press, 'space') == 1)
        break
    end
   end
end
    
    
% Tell the participant this run is over
  message = 'This run is over.';
  DrawFormattedText(w, message, 'center', 'center', WhiteIndex(w));
    
% Update the display to show the concluding text:
  Screen('Flip', w);
    
% Stay up for 6 seconds:
  WaitSecs(6.000);
    
% Flip back to black screen and display the total runtime
  [~, EndEx] = Screen('Flip', w);
  RunTime = EndEx - BeginEx;
  disp(RunTime);
    
% Cleanup at end of experiment: close window, show mouse cursor, close result file, switch Matlab/Octave back to priority 0 (normal priority):
  Screen('CloseAll');
  ShowCursor;
  fclose('all');
  Priority(0);
    
% End of experiment:
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