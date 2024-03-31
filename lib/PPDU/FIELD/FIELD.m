%
% classdef FIELD
%
% FIELD superclass of PPDU Fields
%   This should be the superclass of class DATA and SIGNAL
%
% Author: Zhao Yanbo (zhaoyanbo@email.com)
% Date:    Spring 2024
% Course:  Communication Engineering Program Design II
%
% Properties:
%
%   bin              - Binary representation
%   convoluted       - Convoluted data
%   interleaved      - Interleaved data
%   modulated        - Modulated data
%   piloted          - Piloted data
%   ifft64ed         - IFFT-64 transformed data
%   cyclic_prefixed  - Cyclic prefixed data
%
% Methods:
%
%   function obj = FIELD()
%       % FIELD Constructor
%       %   Detailed explanation goes here
%   end
%
%   function obj = pilot(obj, in)
%       % pilot - Perform pilot scrambling
%       %
%       % Inputs:
%       %    in - Input data
%   end
%
%   function obj = IFFT64(obj, in)
%       % IFFT64 - Perform IFFT-64 transformation
%       %
%       % Inputs:
%       %    in - Input data
%   end
%
%   function obj = cyclic_prefix(obj, time_syms)
%       % cyclic_prefix - Add cyclic prefix to data
%       %
%       % Inputs:
%       %    time_syms - Time domain symbols
%   end
%
%   function out = QAM16(~, in)
%       % QAM16 - Perform QAM16 modulation
%       %
%       % Inputs:
%       %    in - Input data
%       %
%       % Output:
%       %    out - Modulated data
%   end
%
%   function out = DE_QAM16(~, in)
%       % DE_QAM16 - Perform QAM16 demodulation
%       %
%       % Inputs:
%       %    in - Input data
%       %
%       % Output:
%       %    out - Demodulated data
%   end
%
%   function out = BPSK(~, in)
%       % BPSK - Perform BPSK modulation
%       %
%       % Inputs:
%       %    in - Input data
%       %
%       % Output:
%       %    out - Modulated data
%   end
%
%   function out = DE_BPSK(~, rx_symbols)
%       % DE_BPSK - Perform BPSK demodulation
%       %
%       % Inputs:
%       %    rx_symbols - Received symbols
%       %
%       % Output:
%       %    out - Demodulated data
%   end
%
classdef FIELD
    % FIELD superclass of PPDU Fields
    %   This should be the superclass of class DATA and SIGNAL

    properties
        bin
        convoluted
        interleaved
        modulated
        piloted
        ifft64ed
        cyclic_prefixed
    end

    methods

        function obj = FIELD()
        end

        function obj = pilot(obj, in)
            PilotScramble = [1 1 1 1 -1 -1 -1 1 -1 -1 -1 -1 1 1 -1 1 -1 -1 1 1 -1 1 1 -1 1 1 1 1 ...
                           1 1 -1 1 1 1 -1 1 1 -1 -1 1 1 1 -1 1 -1 -1 -1 1 -1 1 -1 -1 1 -1 -1 1 1 1 1 1 -1 -1 1 ...
                           1 -1 -1 1 -1 1 -1 1 1 -1 -1 -1 1 1 -1 -1 -1 -1 1 -1 -1 1 -1 1 1 1 1 -1 1 -1 1 -1 1 -1 ...
                           -1 -1 -1 -1 1 -1 1 1 -1 1 -1 1 1 1 -1 -1 1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1];
            NumDataSubc = 48;
            NumSubc = 52;
            DataSubcPatt = [1:5 7:19 21:26 27:32 34:46 48:52]';
            PilotSubcPatt = [6 20 33 47]';
            NumPilotSubc = 4;
            PilotSubcSymbols = [1; 1; 1; -1];
            n_mod_syms = size(in, 2);
            n_ofdm_syms = ceil(n_mod_syms / NumDataSubc);
            in = [in zeros(1, n_ofdm_syms * NumDataSubc - n_mod_syms)];
            scramble_patt = repmat(PilotScramble, 1, ceil(n_ofdm_syms / length(PilotScramble)));
            scramble_patt = scramble_patt(1:n_ofdm_syms);
            mod_ofdm_syms = zeros(NumSubc, n_ofdm_syms);
            mod_ofdm_syms(DataSubcPatt, :) = reshape(in, NumDataSubc, n_ofdm_syms);
            mod_ofdm_syms(PilotSubcPatt, :) = repmat(scramble_patt, NumPilotSubc, 1) .* repmat(PilotSubcSymbols, 1, n_ofdm_syms);
            obj.piloted = mod_ofdm_syms(:).';
        end

        function obj = IFFT64(obj, in)
            UsedSubcIdx = [7:32 34:59]';
            NumSubc = 52;
            num_symbols = size(in, 2) / NumSubc;
            syms_into_ifft = zeros(64, num_symbols);
            syms_into_ifft(UsedSubcIdx, :) = reshape(in(:), NumSubc, num_symbols);
            resample_patt = [33:64 1:32];
            syms_into_ifft(resample_patt, :) = syms_into_ifft;
            time_syms = zeros(1, num_symbols * 64);
            ifft_out = ifft(syms_into_ifft);
            time_syms(1, :) = ifft_out(:).';
            obj.ifft64ed = time_syms;
        end

        function obj = cyclic_prefix(obj, time_syms)
            num_symbols = size(time_syms, 2) / 64;
            time_signal = zeros(1, num_symbols * 80);
            symbols = reshape(time_syms(:), 64, num_symbols);
            tmp_syms = [symbols(49:64, :); symbols];
            tmp_syms(1, :) = tmp_syms(1, :) * 0.5;
            tmp_syms_end(1, :) = symbols(1, :) * 0.5;
            tmp_syms(1, 2:num_symbols) = tmp_syms(1, 2:num_symbols) + tmp_syms_end(1:num_symbols - 1);
            time_signal(:) = tmp_syms(:).';
            obj.cyclic_prefixed = time_signal;
        end

        function out = QAM16(~, in)
            m = 1;
            full_len = length(in);
            for k = -3:2:3
                for l = -3:2:3
                    table(m) = (k + 1i * l) / sqrt(10);
                    m = m + 1;
                end
            end
            table = table([0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10] + 1);
            inp = reshape(in, 4, full_len / 4);
            out = table([8 4 2 1] * inp + 1);
        end

        function out = DE_QAM16(~, in)
            soft_bits = zeros(4 * size(in, 1), size(in, 2));
            bit0 = real(in);
            bit2 = imag(in);
            bit1 = 2 / sqrt(10) - (abs(real(in)));
            bit3 = 2 / sqrt(10) - (abs(imag(in)));
            soft_bits(1:4:size(soft_bits, 1), :) = bit0;
            soft_bits(2:4:size(soft_bits, 1), :) = bit1;
            soft_bits(3:4:size(soft_bits, 1), :) = bit2;
            soft_bits(4:4:size(soft_bits, 1), :) = bit3;
            soft_bits_out_temp = soft_bits(:)';
            out = soft_bits_out_temp > 0;
        end

        function out = BPSK(~, in)
            table = exp(1i * [0 -pi]);
            table = table([1 0] + 1);
            inp = in;
            out = table(inp + 1);
        end

        function out = DE_BPSK(~, rx_symbols)
            out = real(rx_symbols) > 0;
        end

    end
end
