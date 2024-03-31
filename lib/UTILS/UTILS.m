classdef UTILS
    %INITUTILS Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function obj = UTILS()
            %INITUTILS Construct an instance of this class
            %   Detailed explanation goes here
        end
    end
    methods(Static)

        function [rate,message,scrambling_seed, snr] = show_dialog()
            defaultValue = {'36', 'Across the Great Wall we can reach every corner in the world.', '[1 0 1 0 1 0 1]','20.0'};
            titleBar = 'Enter values';
            userPrompt = {'Select Transmit Rate : ', 'Enter Message: ', 'Enter Srambling Seed', 'AWGN SNR'};
            caUserInput = inputdlg(userPrompt, titleBar, 1, defaultValue);
            if isempty(caUserInput),return,end % Bail out if they clicked Cancel.
            % Convert to floating point from string.
            rate = str2double(caUserInput{1});
            message = caUserInput{2};
            scrambling_seed = str2num(caUserInput{3}); %#ok<ST2NM>
            snr = str2double(caUserInput(4));

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

        function [RATE, code_rate, Pad_Bits, Tail, SERVICE] = rate_handler(rate)
            %RATE_HANDLER Do rate specified configuration
            %   Detailed explanation goes here
            Pad_Bits =[];
            Tail=zeros(1,6);
            SERVICE = zeros(1, 16); 
            if rate == 6
                RATE=[1 1 0 1];                                                     
                code_rate=1/2;
            elseif rate == 36
                RATE=[1 0 1 1];
                code_rate=3/4; 
            else
                error("ERROR RATE, PLEASE SELECT BETWEEN 6 AND 36")
            end
        end
        function rate = rate_resolver(in)
            rate_out=in(1,1:4);
            if rate_out==[1 1 0 1]
                rate = 1/2;
            elseif rate_out==[1 0 1 1] %#ok<*BDSCA> 
                rate = 3/4;
            else 
                error_message = "CODE RATE NOT DETECTED: " + num2str(rate_out) + " is not [1 1 0 1] or [1 0 1 1]";
                error(error_message)
            end
        end
        function refresh_gui(b6,b36,msg,seed,snr,a1,a2,a3,a4)
            if b6.Value == true
                trans_rate = 6;
            elseif b36.Value == true
                trans_rate = 36;
            end
            message = msg.Value;
            scrambling_seed = str2num(seed.Value); %#ok<*ST2NM>
            snr_v = snr.Value;
            task = TASK(trans_rate, message,scrambling_seed, snr_v);
            task = task.run();
            [~, ~] = task.analyze_gui(a1, a2, a3, a4);
        end
    end
end

