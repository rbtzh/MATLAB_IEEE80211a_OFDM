classdef SIGNAL_RX < SIGNAL
    % SIGNAL_RX
    %

    properties
    end

    methods

        function obj = SIGNAL_RX(in)
            obj.modulated = in;
        end

        function obj = de_modulator(obj, in)
            obj.interleaved = obj.DE_BPSK(in);
        end

        function obj = de_interleaver(obj, in)
            block_size = 48;
            s = max(block_size / 96, 1);
            perm_patt = s * floor((0:block_size - 1) / s) + mod((0:block_size - 1) + floor(16 * (0:block_size - 1) / block_size), s);
            deintlvr_patt = 16 * perm_patt - (block_size - 1) * floor(16 * perm_patt / block_size);
            single_deintlvr_patt = deintlvr_patt + 1;
            block_bits = reshape(in, block_size, length(in) / block_size);
            out_signal(single_deintlvr_patt, :) = block_bits;
            obj.convoluted = out_signal(:).';
        end

        function obj = de_convolver(obj, in, code_rate)
            if code_rate == 3 / 4
                TRELLIS = poly2trellis([3 3 3], [7 7 0 4; 3 2 7 4; 0 2 3 7]);
            elseif code_rate == 1 / 2
                TRELLIS = poly2trellis(7, [133, 171]);
            else
                error('Undefined convolutional code rate');
            end

            CODE = in;
            TBLEN = 7;
            OPMODE = 'trunc';
            DECTYPE = 'hard';
            signalout = vitdec(CODE, TRELLIS, TBLEN, OPMODE, DECTYPE);
            obj.bin = signalout;
        end

    end
end
