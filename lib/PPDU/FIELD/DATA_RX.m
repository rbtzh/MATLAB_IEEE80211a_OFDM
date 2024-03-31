classdef DATA_RX < DATA
    % DATA_RX 此处显示有关此类的摘要
    %   此处显示详细说明

    methods

        function obj = DATA_RX(in)
            obj.modulated = in;
        end

        function obj = de_modulator(obj, in, code_rate)
            if code_rate == 1 / 2
                obj.interleaved = obj.DE_BPSK(in);
            elseif code_rate == 3 / 4
                obj.interleaved = obj.DE_QAM16(in);
            end
        end

        function obj = de_interleaver(obj, in, code_rate)
            if code_rate == 3 / 4
                block_size = 192;
            else
                block_size = 48;
            end

            s = max(block_size / 96, 1); 
            perm_patt = s * floor((0:block_size - 1) / s) + mod((0:block_size - 1) + floor(16 * (0:block_size - 1) / block_size), s);
            deintlvr_patt = 16 * perm_patt - (block_size - 1) * floor(16 * perm_patt / block_size);
            single_deintlvr_patt = deintlvr_patt + 1;
            block_bits = reshape(in, block_size, length(in) / block_size);
            out_bits(single_deintlvr_patt, :) = block_bits;
            obj.convoluted = out_bits(:).';
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
            obj.scrambled = vitdec(CODE, TRELLIS, TBLEN, OPMODE, DECTYPE);
        end

        function obj = de_scrambler(obj, in)
            s = in(1:7);
            x1 = xor(s(1, 3), s(1, 7));
            x2 = xor(s(1, 2), s(1, 6));
            x3 = xor(s(1, 1), s(1, 5));
            x4 = xor(x1, s(1, 4));
            seed = [x1, x2, x3, x4, xor(x2, s(1, 3)), xor(x3, s(1, 2)), xor(x4, s(1, 1))];
            data_length = length(in);
            scramb_temp = zeros(1, 127);

            for i = 1:127
                Temp = xor(seed(4), seed(7));
                seed = [Temp, seed(1, 1:6)];
                scramb_temp(i) = Temp;
            end
            
            out_temp = repmat(scramb_temp, 1, ceil(data_length / length(scramb_temp)));
            scramb_temp = out_temp(1:data_length);
            obj.bin = xor(in, scramb_temp);
        end

    end
end
