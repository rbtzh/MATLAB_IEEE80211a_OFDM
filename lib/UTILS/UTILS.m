%
% classdef UTILS
%
% INITUTILS Summary of this class goes here
%   Detailed explanation goes here
%
% Author: Zhao Yanbo (zhaoyanbo@email.com)
% Date:    Spring 2024
% Course:  Communication Engineering Program Design II
%
% Methods:
%
%   function obj = UTILS()
%       % INITUTILS Construct an instance of this class
%       %   Detailed explanation goes here
%   end
%
%   function [rate, message, scrambling_seed, snr] = show_dialog()
%       % show_dialog - Display a dialog box to enter values
%       %
%       % Outputs:
%       %    rate - Selected transmit rate
%       %    message - Entered message
%       %    scrambling_seed - Entered scrambling seed
%       %    snr - AWGN Signal-to-Noise Ratio
%   end
%
%   function [RATE, code_rate, Pad_Bits, Tail, SERVICE] = rate_handler(rate)
%       % rate_handler - Handle rate specified configuration
%       %
%       % Inputs:
%       %    rate - Specified transmission rate
%       %
%       % Outputs:
%       %    RATE - Rate configuration
%       %    code_rate - Code rate
%       %    Pad_Bits - Padded bits
%       %    Tail - Tail bits
%       %    SERVICE - Service bits
%   end
%
%   function rate = rate_resolver(in)
%       % rate_resolver - Resolve the transmission rate
%       %
%       % Inputs:
%       %    in - Input data
%       %
%       % Output:
%       %    rate - Resolved rate
%   end
%
%   function refresh_gui(b6, b36, msg, seed, snr, a1, a2, a3, a4, lamp)
%       % refresh_gui - Refresh the GUI based on user inputs
%       %
%       % Inputs:
%       %    b6 - Button for rate 6
%       %    b36 - Button for rate 36
%       %    msg - Message input field
%       %    seed - Scrambling seed input field
%       %    snr - SNR input field
%       %    a1, a2, a3, a4 - Additional parameters
%       %    lamp - Indicator lamp
%   end
%
classdef UTILS
    % INITUTILS Summary of this class goes here
    %   Detailed explanation goes here
    methods

        function obj = UTILS()
            % INITUTILS Construct an instance of this class
            %   Detailed explanation goes here
        end

    end
    methods (Static)

        function [rate, message, scrambling_seed, snr] = show_dialog()
            defaultValue = {'36', 'Across the Great Wall we can reach every corner in the world.', '[1 0 1 0 1 0 1]', '20.0'};
            titleBar = 'Enter values';
            userPrompt = {'Select Transmit Rate : ', 'Enter Message: ', 'Enter Srambling Seed', 'AWGN SNR'};
            caUserInput = inputdlg(userPrompt, titleBar, 1, defaultValue);
            if isempty(caUserInput)
                return
            end % Bail out if they clicked Cancel.
            % Convert to floating point from string.
            rate = str2double(caUserInput{1});
            message = caUserInput{2};
            scrambling_seed = str2num(caUserInput{3}); %#ok<ST2NM>
            snr = str2double(caUserInput(4));
        end

        function [RATE, code_rate, Pad_Bits, Tail, SERVICE] = rate_handler(rate)
            % RATE_HANDLER Do rate specified configuration
            %   Detailed explanation goes here
            Pad_Bits = [];
            Tail = zeros(1, 6);
            SERVICE = zeros(1, 16);
            if rate == 6
                RATE = [1 1 0 1];
                code_rate = 1 / 2;
            elseif rate == 36
                RATE = [1 0 1 1];
                code_rate = 3 / 4;
            else
                error("ERROR RATE, PLEASE SELECT BETWEEN 6 AND 36");
            end
        end

        function rate = rate_resolver(in)
            rate_out = in(1, 1:4);
            if rate_out == [1 1 0 1]
                rate = 1 / 2;
            elseif rate_out == [1 0 1 1] %#ok<*BDSCA>
                rate = 3 / 4;
            else
                error_message = "CODE RATE NOT DETECTED: " + num2str(rate_out) + " is not [1 1 0 1] or [1 0 1 1]";
                error(error_message);
            end
        end

        function refresh_gui(b6, b36, msg, seed, snr, a1, a2, a3, a4, lamp)
            if b6.Value == true
                trans_rate = 6;
            elseif b36.Value == true
                trans_rate = 36;
            end
            red = [0.85, 0.33, 0.10];
            green = [0.47, 0.67, 0.19];
            lamp.Color = green;
            message = msg.Value;
            scrambling_seed = str2num(seed.Value); %#ok<*ST2NM>
            snr_v = snr.Value;
            task = TASK(trans_rate, message, scrambling_seed, snr_v);
            try
                task = task.run();
                [~, ~] = task.analyze_gui(a1, a2, a3, a4);
            catch
                lamp.Color = red;
            end
        end

    end
end
