%
% classdef TASK
%
% TASK a complete task that can be called
%   Detailed explanation goes here
%
% Author: Zhao Yanbo (zhaoyanbo@email.com)
% Date:    Spring 2024
% Course:  Communication Engineering Program Design II
%
% Properties:
%
%   trans_rate       - Transmission rate
%   message          - Message
%   scrambling_seed  - Scrambling seed
%   snr              - Signal-to-Noise Ratio
%   code_rate        - Code rate
%   tx_signal        - Transmitted signal
%   tx_data          - Transmitted data
%   rx_signal        - Received signal
%   rx_data          - Received data
%
% Methods:
%
%   function obj = TASK(trans_rate, message, scrambling_seed, snr)
%       % TASK Construct an instance of this class
%       %   Detailed explanation goes here
%   end
%
%   function obj = run(obj)
%       % METHOD1 Summary of this method goes here
%       %   Detailed explanation goes here
%   end
%
%   function [errors_signal, errors_data] = analyze(obj, isGraph)
%       % analyze - Analyze the transmitted and received data
%       %
%       % Inputs:
%       %    isGraph - Flag to indicate if graphs should be plotted
%       %
%       % Outputs:
%       %    errors_signal - Error percentage in signal field
%       %    errors_data   - Error percentage in data field
%   end
%
%   function [errors_signal, errors_data] = analyze_gui(obj, g1, g2, g3, g4)
%       % analyze_gui - Analyze the transmitted and received data for GUI
%       %
%       % Inputs:
%       %    g1, g2, g3, g4 - Graph objects for plotting
%       %
%       % Outputs:
%       %    errors_signal - Error percentage in signal field
%       %    errors_data   - Error percentage in data field
%   end
%
% Methods (Static):
%
%   function d = diff(a, b, field)
%       % diff - Calculate error percentage between two arrays
%       %
%       % Inputs:
%       %    a - Array 1
%       %    b - Array 2
%       %    field - Field name for display
%       %
%       % Outputs:
%       %    d - Error percentage
%   end
%
%   function iq_figure_constellation(ts, rs, td, rd, rate, snr)
%       % iq_figure_constellation - Plot constellation diagram
%       %
%       % Inputs:
%       %    ts, rs - Transmitted and received signal objects
%       %    td, rd - Transmitted and received data objects
%       %    rate   - Code rate
%       %    snr    - Signal-to-Noise Ratio
%   end
%
%   function iq_figure_constellation_gui(ts, rs, td, rd, rate, snr, fig1, fig2, fig3, fig4)
%       % iq_figure_constellation_gui - Plot constellation diagram for GUI
%       %
%       % Inputs:
%       %    ts, rs - Transmitted and received signal objects
%       %    td, rd - Transmitted and received data objects
%       %    rate   - Code rate
%       %    snr    - Signal-to-Noise Ratio
%       %    fig1, fig2, fig3, fig4 - Graph objects for plotting
%   end
%
classdef TASK
    % TASK a complete task that can be called
    %   Detailed explanation goes here

    properties
        trans_rate
        message
        scrambling_seed
        snr
        code_rate
        tx_signal
        tx_data
        rx_signal
        rx_data
    end

    methods

        function obj = TASK(trans_rate, message, scrambling_seed, snr)
            % TASK Construct an instance of this class
            %   Detailed explanation goes here
            obj.trans_rate = trans_rate;
            obj.message = message;
            obj.scrambling_seed = scrambling_seed;
            obj.snr = snr;
        end

        function obj = run(obj)
            % METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %% 信源 MAC地址配置 MAC层成帧 SERVICE FIELD生成
            % calculation of MAC layer data passed to PHY layer
            % Do someting rate specified configuration
            [RATE, code_rate_tx, Pad_Bits, Tail, SERVICE] = UTILS.rate_handler(obj.trans_rate);

            %% 生成 PSDU
            % PSDU construction
            psdu = PSDU(obj.message);

            %% 生成 DATA 段
            % DATA field/object construction
            data_tx = DATA_TX(SERVICE, psdu.bin, Tail, Pad_Bits, code_rate_tx);
            %% DATA 加扰
            % DATA field scrambling
            data_tx = data_tx.scrambler(data_tx.bin, obj.scrambling_seed);
            %% DATA 卷积编码
            % DATA field convolution encoding
            data_tx = data_tx.convolver_tx(data_tx.scrambled, code_rate_tx);
            %% DATA 交织编码
            % DATA field interleaved encoding
            data_tx = data_tx.interleaver_tx(data_tx.convoluted, code_rate_tx);
            %% DATA 调制
            % DATA field Modulation
            data_tx = data_tx.modulator(data_tx.interleaved, code_rate_tx);
            %% DATA 添加导频
            % DATA field add pilot
            data_tx = data_tx.pilot(data_tx.modulated);
            %% DATA 进行 IFFT64 运算
            % DATA field do IFFT64 calculation
            data_tx = data_tx.IFFT64(data_tx.piloted);
            %% DATA 添加循环前缀
            % DATA field add cyclic prefix
            data_tx = data_tx.cyclic_prefix(data_tx.ifft64ed);

            %% 生成 SIGNAL 段
            % SIGNAL field/object construction
            signal_tx = SIGNAL_TX(RATE, psdu.length);
            %% SIGNAL 卷积编码
            % SIGNAL field convolution encoding
            signal_tx = signal_tx.convolver(signal_tx.bin);
            %% SIGNAL 交织编码
            % SIGNAL field interleaved encoding
            signal_tx = signal_tx.interleaver(signal_tx.convoluted);
            %% SIGNAL 调制
            % SIGNAL field Modulation
            signal_tx = signal_tx.modulator(signal_tx.interleaved);
            %% SIGNAL 添加导频
            % SIGNAL field add pilot
            signal_tx = signal_tx.pilot(signal_tx.modulated);
            %% SIGNAL 进行 IFFT64 运算
            % SIGNAL field do IFFT64 calculation
            signal_tx = signal_tx.IFFT64(signal_tx.piloted);
            %% SIGNAL 添加循环前缀
            % SIGNAL field add cyclic prefix
            signal_tx = signal_tx.cyclic_prefix(signal_tx.ifft64ed);

            %% 生成 PREAMBLE 段
            % PREAMABLE field/object construction
            preamable = PREAMBLE();

            %% 生成 PPDU
            % PPDU construction
            ppdu = PPDU(preamable, signal_tx, data_tx);

            %% 通过 AWGN 信道
            ppdu.content = awgn(ppdu.content, obj.snr);

            %% 提取接收端 SIGNAL 与 DATA 的原始数据

            [~, freq_data_syms, ~] = FFT64(ppdu.content);

            e = freq_data_syms;
            w = length(e);
            signal_raw = e(1:48);
            data_raw = e(49:w);

            %% SIGNAL 接收
            signal_rx = SIGNAL_RX(signal_raw);
            %% SIGNAL 解调
            signal_rx = signal_rx.de_modulator(signal_rx.modulated);
            %% SIGNAL 解交织编码
            signal_rx = signal_rx.de_interleaver(signal_rx.interleaved);
            %% SIGNAL 解卷积编码
            signal_rx = signal_rx.de_convolver(signal_rx.convoluted, 1 / 2);
            %% 从 SIGNAL 中检测 code rate
            code_rate_rx = UTILS.rate_resolver(signal_rx.bin);
            %% DATA 接收
            data_rx = DATA_RX(data_raw);
            %% DATA 解调
            data_rx = data_rx.de_modulator(data_rx.modulated, code_rate_rx);
            %% DATA 解交织编码
            data_rx = data_rx.de_interleaver(data_rx.interleaved, code_rate_rx);
            %% DATA 解卷积编码
            data_rx = data_rx.de_convolver(data_rx.convoluted, code_rate_rx);
            %% DATA 解扰码
            data_rx = data_rx.de_scrambler(data_rx.scrambled);

            %% 保存实验结果
            obj.code_rate = code_rate_tx;
            obj.tx_data = data_tx;
            obj.tx_signal = signal_tx;
            obj.rx_data = data_rx;
            obj.rx_signal = signal_rx;

        end

        function [errors_signal, errors_data] = analyze(obj, isGraph)
            ts = obj.tx_signal;
            rs = obj.rx_signal;
            td = obj.tx_data;
            rd = obj.rx_data;

            %% SIGNAL 检测发送与接收内容差异
            % TODO ABSTRACT THIS AS PROPERTIES AND METHODS OF TASK
            errors_signal = obj.diff(ts.bin, rs.bin, "signal field");

            %% DATA 检测发送与接收内容差异
            % TODO ABSTRACT THIS AS PROPERTIES AND METHODS OF TASK
            errors_data = obj.diff(td.bin, rd.bin, "data field");

            if isGraph
                %% 画出星座图
                %% Draw Constellation diagram
                obj.iq_figure_constellation(ts, rs, td, rd, obj.code_rate, obj.snr);
                %% 画出瀑布图
            end

        end

        function [errors_signal, errors_data] = analyze_gui(obj, g1, g2, g3, g4)
            ts = obj.tx_signal;
            rs = obj.rx_signal;
            td = obj.tx_data;
            rd = obj.rx_data;

            %% SIGNAL 检测发送与接收内容差异
            % TODO ABSTRACT THIS AS PROPERTIES AND METHODS OF TASK
            errors_signal = obj.diff(ts.bin, rs.bin, "signal field");

            %% DATA 检测发送与接收内容差异
            % TODO ABSTRACT THIS AS PROPERTIES AND METHODS OF TASK
            errors_data = obj.diff(td.bin, rd.bin, "data field");

            %% 画出星座图
            %% Draw Constellation diagram
            obj.iq_figure_constellation_gui(ts, rs, td, rd, obj.code_rate, obj.snr, g1, g2, g3, g4);
            %% 画出瀑布图

        end

    end

    methods (Static)

        function d = diff(a, b, field)
            xor_signal = xor(a, b);
            ones_signal = numel(find(xor_signal == 1));
            d = ones_signal / 24 * 100;
            if nargin >= 3
                sprintf("error in %s is %f", field, d);
            end
        end

        function iq_figure_constellation(ts, rs, td, rd, rate, snr)

            if rate == 1 / 2
                title_iq_data = 'BPSK';
                speed = 6;
            elseif rate == 3 / 4
                title_iq_data = '16QAM';
                speed = 36;
            else
                error("ERROR RATE");
            end

            % Draw Constellation diagram
            figure;
            sgt = sgtitle(sprintf('IEEE 802.11a-1999 OFDM Simulation \nConstellation Diagram\nData Rate = %d Mbps, AWGN SNR = %d dB', speed, snr));
            sgt.FontSize = 15;

            set(gcf, 'unit', 'centimeters', 'position', [0 0 20 20]);
            % 1. Tx Signal
            subplot(2, 2, 1);
            r = real(ts.modulated);
            l = imag(ts.modulated);
            scatter(r, l, '*');
            hold on;
            grid on;
            axis([-1 1, -1 1]);
            xlabel('I');
            ylabel('Q');
            title('BPSK Signal Field, Tx', 'BPSK');

            % 2. Rx Signal
            subplot(2, 2, 2);
            r = real(rs.modulated);
            l = imag(rs.modulated);
            scatter(r, l, '*');
            hold on;
            grid on;
            axis([-0.5 0.5, -0.5 0.5]);
            xlabel('I');
            ylabel('Q');
            title('Signal Field, Rx', 'BPSK');

            % 3. Tx Data
            subplot(2, 2, 3);
            r = real(td.modulated);
            l = imag(td.modulated);
            scatter(r, l, '*');
            hold on;
            grid on;
            axis([-1 1, -1 1]);
            xlabel('I');
            ylabel('Q');
            title(' Data Field, Tx', title_iq_data);

            % 4, Rx Data
            subplot(2, 2, 4);
            r = real(rd.modulated);
            l = imag(rd.modulated);
            scatter(r, l, '*');
            hold on;
            grid on;
            axis([-0.5 0.5, -0.5 0.5]);
            xlabel('I');
            ylabel('Q');
            title(' Data Field, Rx', title_iq_data);
        end

        function iq_figure_constellation_gui(ts, rs, td, rd, rate, snr, fig1, fig2, fig3, fig4)

            if rate == 1 / 2
                title_iq_data = 'BPSK';
                speed = 6;
            elseif rate == 3 / 4
                title_iq_data = '16QAM';
                speed = 36;
            else
                error("ERROR RATE");
            end

            % Draw Constellation diagram
            % 1. Tx Signal
            r = real(ts.modulated);
            l = imag(ts.modulated);
            scatter1 = scatter(fig1, r, l, '*');
            hold on;
            grid on;
            axis(fig1, [-1 1, -1 1]);
            xlabel(fig1, 'I');
            ylabel(fig1, 'Q');
            title(fig1, 'BPSK Signal Field, Tx', 'BPSK');

            % 2. Rx Signal
            r = real(rs.modulated);
            l = imag(rs.modulated);
            scatter(fig2, r, l, '*');
            hold on;
            grid on;
            axis([-0.5 0.5, -0.5 0.5]);
            xlabel(fig2, 'I');
            ylabel(fig2, 'Q');
            title(fig2, 'Signal Field, Rx', 'BPSK');

            % 3. Tx Data
            r = real(td.modulated);
            l = imag(td.modulated);
            scatter(fig3, r, l, '*');
            hold on;
            grid on;
            axis(fig3, [-1 1, -1 1]);
            xlabel(fig3, 'I');
            ylabel(fig3, 'Q');
            title(fig3, ' Data Field, Tx', title_iq_data);

            % 4, Rx Data
            r = real(rd.modulated);
            l = imag(rd.modulated);
            scatter(fig4, r, l, '*');
            hold on;
            grid on;
            xlabel(fig4, 'I');
            ylabel(fig4, 'Q');
            title(fig4, ' Data Field, Rx', title_iq_data);
        end

    end

end
