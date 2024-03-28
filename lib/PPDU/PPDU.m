classdef PPDU
    properties
        preamble
        signal
        data
    end
    methods
        function obj = PPDU(preamble, signal,data)
            obj.preamble = preamble;
            obj.signal = signal;
            obj.data = data;
        end

        function modulation_signal()
        end
        function modulation_data()
        end
    end
end