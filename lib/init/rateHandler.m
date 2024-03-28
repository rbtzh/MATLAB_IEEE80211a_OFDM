function [RATE, code_rate, Pad_Bits, Tail, SERVICE] = rateHandler(rate)
    addpath(genpath('../'))
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
