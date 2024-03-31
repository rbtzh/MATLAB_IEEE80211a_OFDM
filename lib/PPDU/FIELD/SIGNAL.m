classdef SIGNAL < FIELD
    % SIGANl field in PPDU

    properties (Access = protected)
        rate
        reserved = 0
        len
        parity = 0
        tail = zeros(1, 6)
    end

    methods

        function obj = SIGNAL()
        end

    end
end
