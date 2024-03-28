classdef PPDU
    properties
        preamble
        signal
        data
    end
    methods
        function obj = PPDU(signal_rate, psdu)
            obj.preamble = PREAMBLE();
            obj.signal = SIGNAL(signal_rate, length(psdu));
        end
    end
end