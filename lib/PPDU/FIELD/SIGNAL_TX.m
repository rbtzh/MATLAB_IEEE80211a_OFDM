classdef SIGNAL_TX < SIGNAL
    % SIGNAL_TX
    %

    methods

        function obj = SIGNAL_TX(rate, PSDU_length)
            obj.rate = rate;
            dec = dec2bin(PSDU_length);
            zero1 = zeros(1, 12 - length(dec));
            binRate = str2num(dec(:))'; %#ok<ST2NM>
            obj.len = [zero1 binRate];
            obj.bin = [obj.rate obj.reserved obj.len obj.parity obj.tail];
        end

        function obj = convolver(obj, in)

            ConvCodeGenPoly = [1 0 1 1 0 1 1; 1 1 1 1 0 0 1];
            number_rows = size(ConvCodeGenPoly, 1);
            number_bits = size(ConvCodeGenPoly, 2) + length(in) - 1;
            uncoded_bits = zeros(number_rows, number_bits); 

            for row = 1:number_rows
                uncoded_bits(row, 1:number_bits) = rem(conv(in * 1, ConvCodeGenPoly(row, :)), 2);
            end
            
            coded_bits = uncoded_bits(:);
            coded_bits1 = coded_bits(:).';
            punc_patt = [1 2 3 4 5 6];
            punc_patt_size = 6;
            coded_bits = coded_bits1(1:length(coded_bits1) - 12);
            num_rem_bits = rem(length(coded_bits), punc_patt_size);
            puncture_table = reshape(coded_bits(1:length(coded_bits) - num_rem_bits), punc_patt_size, fix(length(coded_bits) / punc_patt_size));
            tx_table = puncture_table(punc_patt, :);
            rem_bits = coded_bits(length(coded_bits) - num_rem_bits + 1:length(coded_bits));
            rem_punc_patt = find(punc_patt <= num_rem_bits);
            rem_punc_bits = zeros(1, num_rem_bits);
            rem_punc_bits(rem_punc_patt) = rem_bits(rem_punc_patt);
            punctured_bits = [tx_table(:)' rem_punc_bits];
            obj.convoluted = punctured_bits;
        end

        function obj = interleaver(obj, in)
            block_size = 48;
            Ofdm_ = ceil(length(in) / block_size);
            Pad0 = zeros(1, Ofdm_ * block_size - length(in));
            in = [in Pad0];
            block_bits = reshape(in, block_size, length(in) / block_size);
            m_k = block_size / 16 * mod(0:block_size - 1, 16) + floor((0:block_size - 1) / 16);
            s = max(block_size / 96, 1);
            j_k = s * floor(m_k / s) + mod(m_k + block_size - floor(16 * m_k / block_size), s);
            idx(j_k + 1, :) = block_bits;
            obj.interleaved = idx(:).';
        end

        function obj = modulator(obj, in)
            obj.modulated = obj.BPSK(in);
        end

    end
end
