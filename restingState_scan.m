function restingState_scan

% setup the path
addpath('P:\MATLAB\PsychToolbox\3.0.11');
BIACSetupPsychtoolbox;
AssertOpenGL;

practice = input('Practice?: ');

% find pulse counter
try
   daq = DaqDeviceIndex();
 catch
   error('Daq device not found');
end


if practice == 0
    minutes = 7;
elseif practice == 1
    minutes = 1;
end

%% start resting state scan w/ TTL pulse %%
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
