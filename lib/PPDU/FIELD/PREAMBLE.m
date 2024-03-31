classdef PREAMBLE
    % PREAMBLE Summary of this class goes here
    %   This Object generates preamble sequence for 802.11a

    properties
        short
        long
        content
    end
    properties (Access = private)
        % Train Sequence
        TRAIN_SHORT = sqrt(13 / 6) * [0 0 1 + 1i 0 0 0 -1 - 1i 0 0 0 1 + 1i 0 0 0 -1 - 1i ...
                                   0 0 0 -1 - 1i 0 0 0 1 + 1i 0 0 0 0 0 0 -1 - 1i 0 0 0 ...
                                   -1 - 1i 0 0 0 1 + 1i 0 0 0 1 + 1i 0 0 0 1 + 1i 0 0 0 1 + 1i 0 0].'
        TRAIN_LONG = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 ...
                      1 1 1 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 ...
                      -1 1 -1 1 1 1 1].'
    end

    methods

        function obj = PREAMBLE()
            % PREAMBLE Construct an instance of this class
            % use methods to calculate the short and long sequences of
            % preamble
            obj.short = obj.Get_Preamble_Short();
            obj.long = obj.Get_Preamble_Long();
            obj.content = [obj.short; obj.long].';
        end

    end
    methods (Access = private)

        % generate short sequence
        function preamble_short = Get_Preamble_Short(obj)
            short_demap = zeros(64, 1);
            short_demap([7:32 34:59], :) = obj.TRAIN_SHORT;
            short_demap([33:64 1:32], :) = short_demap;

            preamble_short_unit = sqrt(64) * ifft(sqrt(64 / 52) * short_demap);
            preamble_short_unit = preamble_short_unit(1:16);
            preamble_short = repmat(preamble_short_unit, 10, 1);
        end

        % generate long sequence
        function preamble_long = Get_Preamble_Long(obj)
            long_demap = zeros(64, 1);
            long_demap([7:32 34:59], :) = obj.TRAIN_LONG;
            long_demap([33:64 1:32], :) = long_demap;
            preamble_long_unit = sqrt(64) * ifft(sqrt(64 / 52) * long_demap);
            preamble_long = [preamble_long_unit(33:64, :); preamble_long_unit; ...
                             preamble_long_unit];
        end

    end
end
