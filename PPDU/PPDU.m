classdef PPDU
    properties
        preamble
        signal
        data
        
        signal_rate
        signal_reserved
        signal_length
        signal_parity
        data_service
        data_psdu
        data_tail
        data_padbits
    end
    methods
        function obj = PPDU()
            obj.preamble = PREAMBLE();
        end
    end
end