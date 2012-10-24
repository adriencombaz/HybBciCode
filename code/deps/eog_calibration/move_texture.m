function move_texture(window, texture, textureSize, from, to, duration, interpolation, beforeFlip)

if nargin < 6
    interpolation = 'sine';
end

black = BlackIndex(window);
start = GetSecs;

progress = 0.0;
while progress < 1.0
    if strcmp(interpolation, 'sine')
        % Sine interpolation
        i = sin(progress * pi / 2);
    elseif strcmp(interpolation, 'inv-sine')
        % Inverse sine interpolation
        i = 1 - sin((progress+1) * pi / 2);
    else
        % Linear interpolation
        i = progress;
    end
    currPos = i .* to + (1.0 - i) .* from;
    Screen('FillRect', window, black);
    Screen('DrawTexture', window, texture, [], [currPos currPos+textureSize]);
    
    if nargin >= 8
        beforeFlip();
    end
    
    [bla, bla, onset] = Screen('Flip', window);
    progress = (onset - start) / duration;
end

end
