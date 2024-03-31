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
                           -1 -1 -1 -1 1 -1 1 1 -1 1 -1 1 1 1 -1 -1 1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1]; % 导频伪随机序列
            NumDataSubc = 48; % 数据子载波数
            NumSubc = 52; % 子载波数
            DataSubcPatt = [1:5 7:19 21:26 27:32 34:46 48:52]'; % 数据子载波的位置
            PilotSubcPatt = [6 20 33 47]'; % 导频子载波的位置
            NumPilotSubc = 4; % 导频子载波数
            PilotSubcSymbols = [1; 1; 1; -1]; % 导频子载波的符号

            n_mod_syms = size(in, 2); % 发送的映射调制符号数
            n_ofdm_syms = ceil(n_mod_syms / NumDataSubc); % 发送的OFDM符号数
            in = [in zeros(1, n_ofdm_syms * NumDataSubc - n_mod_syms)];

            % 导频加扰模式
            scramble_patt = repmat(PilotScramble, 1, ceil(n_ofdm_syms / length(PilotScramble))); % 重复导频扰码，使得其长度至少与OFDM符号数一样
            scramble_patt = scramble_patt(1:n_ofdm_syms); % 截取与OFDM符号数个导频扰码序列

            mod_ofdm_syms = zeros(NumSubc, n_ofdm_syms);
            mod_ofdm_syms(DataSubcPatt, :) = reshape(in, NumDataSubc, n_ofdm_syms); % 将映射调制符号mod_syms按分组插入NumDataSubc个数据子载波中

            % 将导频子载波符号序列进行扰码后插入相应导频子载波位置上
            mod_ofdm_syms(PilotSubcPatt, :) = repmat(scramble_patt, NumPilotSubc, 1) .* repmat(PilotSubcSymbols, 1, n_ofdm_syms);
            % 导频插入后的数据输出
            obj.piloted = mod_ofdm_syms(:).';
        end

        function obj = IFFT64(obj, in)
            % IFFT64：信号由频域变换到时域
            UsedSubcIdx = [7:32 34:59]'; % 使用的子载波索引
            NumSubc = 52; % 子载波数

            % OFDM符号数
            num_symbols = size(in, 2) / NumSubc;

            % 将数据加到相应子载波上，并在未使用的子载波上补0
            syms_into_ifft = zeros(64, num_symbols);
            syms_into_ifft(UsedSubcIdx, :) = reshape(in(:), NumSubc, num_symbols);

            % 数据位置置换
            resample_patt = [33:64 1:32];
            syms_into_ifft(resample_patt, :) = syms_into_ifft;

            % 变换到时域
            time_syms = zeros(1, num_symbols * 64); % 初始化time_syms
            ifft_out = ifft(syms_into_ifft);
            time_syms(1, :) = ifft_out(:).';
            obj.ifft64ed = time_syms;
        end

        function obj = cyclic_prefix(obj, time_syms)
            num_symbols = size(time_syms, 2) / 64;      % 需要传输的符号数（每符号有64数据码元）
            time_signal = zeros(1, num_symbols * 80);   % 产生时域信号的初始状态；

            % 增加循环前缀
            symbols = reshape(time_syms(:), 64, num_symbols);
            tmp_syms = [symbols(49:64, :); symbols];    % 取一个符号后16bit
            tmp_syms(1, :) = tmp_syms(1, :) * 0.5;           % 对符号的首尾进行加窗处理
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
                    table(m) = (k + 1i * l) / sqrt(10); % 功率归一化（1/sqrt(10)）
                    m = m + 1;
                end
            end
            table = table([0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10] + 1); % 8-psk符号的格雷码映射模式
            inp = reshape(in, 4, full_len / 4);
            out = table([8 4 2 1] * inp + 1);  % 将传输的比特映射为16个QAM符号
            % r = real(out);
            % l = imag(out);
            % scatter(r,l,'*');
            % hold on
            % grid on
            % axis([-1 1,-1 1]);
            % xlabel('I');
            % ylabel('Q');
            % title('16-QAM星座图');
        end

        function out = DE_QAM16(~, in)
            soft_bits = zeros(4 * size(in, 1), size(in, 2));  % 每个符号由4位组成

            bit0 = real(in);   % 实部
            bit2 = imag(in);   % 虚部

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

            table = exp(1i * [0 -pi]);  % 生成BPSK序列(欧拉公式)
            table = table([1 0] + 1); % bpsk符号的格雷码映射模式
            inp = in;
            out = table(inp + 1); % 将传输的比特映射为bpsk符号
            % r = real(out);
            % l = imag(out);
            % scatter(r,l,'*');
        end

        function out = DE_BPSK(~, rx_symbols)

            out = real(rx_symbols) > 0;
        end

    end
end
