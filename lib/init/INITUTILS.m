classdef INITUTILS
    %INITUTILS Summary of this class goes here
    %   Detailed explanation goes here
    methods
        function obj = INITUTILS()
            %INITUTILS Construct an instance of this class
            %   Detailed explanation goes here
        end
    end
    methods(Static)

        function [rate,message,scrambling_seed] = show_dialog()
            defaultValue = {'6', 'Across the Great Wall we can reach every corner in the world.', '[1 0 1 0 1 0 1]'};
            titleBar = 'Enter values';
            userPrompt = {'Select Transmit Rate : ', 'Enter Message: ', 'Enter Srambling Seed'};
            caUserInput = inputdlg(userPrompt, titleBar, 1, defaultValue);
            if isempty(caUserInput),return,end % Bail out if they clicked Cancel.
            % Convert to floating point from string.
            rate = str2double(caUserInput{1});
            message = caUserInput{2};
            scrambling_seed = str2num(caUserInput{3}); %#ok<ST2NM>
            
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
            if rate == 6
                RATE=[1 1 0 1];                                                        %6Mbps速率表示      
                % Ncbps = 48;                                                            
                % Ndbps = 24;
                % Nbpsc = 1;                                                             
                code_rate=1/2;
                Pad_Bits =[];                                                          %填充位
                Tail=zeros(1,6);                                                       %尾比特 6bit
                SERVICE = zeros(1, 16);                                                %业务位 16bit
                
            elseif rate == 36
                RATE=[1 0 1 1];                                                            %36Mbps速率
                % Ndbps = 144;
                % Ncbps = 192;
                % Nbpsc = 4;
                code_rate=3/4;
                Pad_Bits =[];                                                              %填充位
                Tail=zeros(1,6);                                                           %尾比特 6bit
                SERVICE = zeros(1, 16);                                                    %业务位 16bit
            else
                error("ERROR RATE, PLEASE SELECT BETWEEN 6 AND 36")
            end
        end
    end
end

