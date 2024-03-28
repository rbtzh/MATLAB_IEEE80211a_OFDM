classdef SIGNAL
    %SIGANl segment in PPDU
    
    properties
        rate
        reserved = 0
        length
        parity = 0
        tail = zeros(1,6)
        bin
    end
    
    methods
        function obj = SIGNAL(rate, PSDU_length)
            obj.rate = rate;
            dec = dec2bin(PSDU_length);
            zero1 = zeros(1, 12 - length(dec));
            binRate = str2num(dec(:))'; %#ok<ST2NM>
            obj.length = [zero1 binRate];
            obj.bin = [obj.rate obj.reserved obj.length obj.parity obj.tail];
        end
    end
end

