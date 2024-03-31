classdef PPDU
    properties
        preamble
        signal
        data
        content
    end
    methods

        function obj = PPDU(preamble, signal, data)
            obj.preamble = preamble;
            obj.signal = signal;
            obj.data = data;
            obj.content = [preamble.content signal.cyclic_prefixed data.cyclic_prefixed];
        end

    end
end
