function [imageList, fixResp, acc] = orientationFix(time, w, practice)
% run in Psychtoolbox, assumes a functioning screen/window.

% duration in seconds
duration = 1.5;

imageList = {};
fixResp = [];

if practice
    rateLeft = KbName('z');
    rateRight = KbName('m');
else
    rateLeft = KbName('1!');
    rateRight = KbName('2@');
end

% figure out how many different arrows we need to have one up for every 1.5 seconds of the active jitter
reps = time/duration;
acc = 0;
images = {'task/Jitter/left1.jpg', 'task/Jitter/left2.jpg', 'task/Jitter/left3.jpg',...
          'task/Jitter/right1.jpg', 'task/Jitter/right2.jpg', 'task/Jitter/right3.jpg'};

for image = 1:reps
    imageChoice = images{randi(6)}; % pick a random images from 'images'
    screenImage = imread(imageChoice); % load it into buffer
    jitterTex = Screen('MakeTexture', w, screenImage);
    Screen('DrawTexture', w, jitterTex);
    Screen('Flip', w); % display it on the screen
    [~, imOnset] = Screen('Flip', w); % store onset time
    resp = 0; % initialize resp
    
    % Keep the image up for 'duration' length of time
    while (GetSecs - imOnset) <= duration
        [~, ~, KeyCode] = KbCheck;
        if KeyCode(rateLeft) || KeyCode(rateRight)
            resp = KbName(KeyCode); % record response
            % if 2 simultaneous responses, take the first of them
            if iscell(resp)
                resp = resp{1};
            end
            if ~practice
                % take out the first item from the response name
                resp = str2double(resp(1)); 
            else
                if strcmp(resp, 'z')
                    resp = 1;
                elseif strcmp(resp, 'm')
                    resp = 2;
                end
            end 
        end
    end
    
    % store name of image & key response
    imageList{end+1} = imageChoice;
    fixResp = [fixResp resp];
    
    % calculate accuracy 
    if ((resp == 1) && (contains(imageChoice, 'left') == 1) || ...
        (resp == 2) && (contains(imageChoice, 'right') == 1))
        acc = acc + 1;
    end
end

acc = acc/reps;

end