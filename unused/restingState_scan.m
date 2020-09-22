function restingState_scan

practice = input('Practice?: ');

    if practice == 0
        addpath('P:\MATLAB\PsychToolbox\3.0.11');
        BIACSetupPsychtoolbox;
        AssertOpenGL;
    elseif practice == 1
        AssertOpenGL;
    end
   

% find pulse counter
if practice == 0
    try
        daq = DaqDeviceIndex();
    catch
        error('Daq device not found');
    end
end


if practice == 0
    minutes = 5;
elseif practice == 1
    minutes = 1;
end

%% start resting state scan w/ TTL pulse %%
screens = Screen('Screens');
screenNumber = max(screens);
HideCursor;
[w, ~] = Screen('OpenWindow', screenNumber, 0);

DrawFormattedText(w, 'Setting up resting state scan...', 'center', 'center', WhiteIndex(w));
Screen('Flip', w);
   
   while 1
   [keyIsDown, ~, ~] = KbCheck;
        if keyIsDown == 1
             break
        end
   end
   
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
   DrawFormattedText(w, 'Relax', 'center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(8.000);
   
   DrawFormattedText(w, '+', 'center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(60*minutes);
   
   Screen('Flip', w);
   WaitSecs(0.5000);
   
   DrawFormattedText(w, 'The experiment is now over.','center', 'center', WhiteIndex(w));
   Screen('Flip', w);
   WaitSecs(4.000);
   
end
