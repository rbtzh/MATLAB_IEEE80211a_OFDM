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

            block_size = 48; % 相应速率对应的每OFDM符号的编码比特数

            s = max(block_size / 96, 1); % Max（每子载波的编码比特数/2,1），其中每子载波的编码比特数= block_size/48
            perm_patt = s * floor((0:block_size - 1) / s) + mod((0:block_size - 1) + floor(16 * (0:block_size - 1) / block_size), s);
            deintlvr_patt = 16 * perm_patt - (block_size - 1) * floor(16 * perm_patt / block_size);
            single_deintlvr_patt = deintlvr_patt + 1;
            block_bits = reshape(in, block_size, length(in) / block_size);
            % 将输入数据按块大小分组，一个块分组为1列，共分为length(in_bits)/block_size列
            % 192行n列
            out_signal(single_deintlvr_patt, :) = block_bits; % 将各个矩阵块的比特与置换后位置对应
            obj.convoluted = out_signal(:).'; % 串行输出
        end

        function obj = de_convolver(obj, in, code_rate)

            % 插入哑元0将信号还原成为编码速率为1/2的卷积码进行解码
            if code_rate == 3 / 4

                TRELLIS = poly2trellis([3 3 3], [7 7 0 4; 3 2 7 4; 0 2 3 7]);  % 实现3输入4输出的卷积编码器
            elseif code_rate == 1 / 2

                TRELLIS = poly2trellis(7, [133, 171]);    % 实现1输入2输出的卷积编码器
            else
                error('Undefined convolutional code rate');
            end

            % 使用Viterbi算法解卷积
            % 原型decoded =vitdec(code,trellis,tblen,opmode,dectype)；
            % trellis：网格表，用来规定我们使用的卷积编码的规则
            % tblen：指定回溯深度的正整数标量
            % opmode：译码器的工作模式及其对相应编码器工作的假设
            % dectype：用于指明译码器的决策类型
            CODE = in;
            TBLEN = 7;
            OPMODE = 'trunc'; % 假设编码器的初始状态为全“0” ；解码器用最佳度量从状态回溯。这种方式不产生延时
            DECTYPE = 'hard'; % 硬判决 二进制输入
            signalout = vitdec(CODE, TRELLIS, TBLEN, OPMODE, DECTYPE);
            obj.bin = signalout;
        end

    end
end
