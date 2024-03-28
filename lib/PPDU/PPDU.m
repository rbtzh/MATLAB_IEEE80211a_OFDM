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
    end
end