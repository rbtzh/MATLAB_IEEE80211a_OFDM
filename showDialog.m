function [rate,message,scrambling_seed] = showDialog()

defaultValue = {'6', 'Across the Great Wall we can reach every corner in the world.', '[1 0 1 0 1 0 1]'};
titleBar = 'Enter values';
userPrompt = {'Select Transmit Rate : ', 'Enter Message: ', 'Enter Srambling Seed'};
caUserInput = inputdlg(userPrompt, titleBar, 1, defaultValue);
if isempty(caUserInput),return,end % Bail out if they clicked Cancel.
% Convert to floating point from string.
rate = str2double(caUserInput{1})
message = caUserInput{2}
scrambling_seed = str2num(caUserInput{3}) %#ok<ST2NM>

% % Check Transmit Rate
% if isnan(rate)
%     % They didn't enter a number.
%     % They clicked Cancel, or entered a character, symbols, or something else not allowed.
%     % Convert the default from a string and stick that into usersValue1.
%     usersValue1 = str2num(defaultValue{1});
%     message = sprintf('I said it had to be a number.\nTry replacing the user.\nI will use %.2f and continue.', usersValue1);
%     uiwait(warndlg(message));
% end

end

