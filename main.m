clear
% clc

addpath(genpath('./lib'))

disp('#############################################');
disp("802.11a OFDM Simulation implemented in MATLAB");
disp('#############################################');

%% 初始化
% initialization
% Get some essential value from user using dialog
[trans_rate,message,scrambling_seed, snr] = UTILS.show_dialog();


%% 信源 MAC地址配置 MAC层成帧 SERVICE FIELD生成
% calculation of MAC layer data passed to PHY layer
% Do someting rate specified configuration
[RATE, code_rate_tx, Pad_Bits, Tail, SERVICE] = UTILS.rate_handler(trans_rate);

%% 生成 PSDU
% PSDU construction
psdu = PSDU(message);

%% 生成 DATA 段
% DATA field/object construction
data_tx = DATA_TX(SERVICE, psdu.bin, Tail, Pad_Bits);

%% DATA 加扰
% DATA field scrambling
data_tx = data_tx.scrambler(data_tx.bin, scrambling_seed);

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
ppdu.content = awgn(ppdu.content,snr); 

%% MAGIC CODE

[~, freq_data_syms, ~] = FFT64(ppdu.content);

e=freq_data_syms;
w=length(e);
signal_raw=e(1:48);
data_raw=e(49:w);

%% SIGNAL 接收
signal_rx= SIGNAL_RX(signal_raw);
%% SIGNAL 解调
signal_rx = signal_rx.de_modulator(signal_rx.modulated);
%% SIGNAL 解交织编码
signal_rx = signal_rx.de_interleaver(signal_rx.interleaved);
%% SIGNAL 解卷积编码
signal_rx = signal_rx.de_convolver(signal_rx.convoluted, 1/2);

%% SIGNAL 分析

signal_tx
signal_rx

%% SIGNAL 检测发送与接收内容差异
%TODO ABSTRACT THIS AS PROPERTIES AND METHODS OF TASK
xor_signal = xor(signal_tx.bin,signal_rx.bin);
ones_signal = numel(find(xor_signal == 1));
errors_signal = ones_signal / 24 * 100;
sprintf("\t\t*****\nerror in signal field is %f\n\t\t*****", errors_signal)

%% 从 SIGNAL 中检测 code rate
code_rate_rx = UTILS.rate_resolver(signal_rx.bin);

%% DATA 接收
data_rx= DATA_RX(data_raw);
%% DATA 解调
data_rx = data_rx.de_modulator(data_rx.modulated, code_rate_rx);
%% DATA 解交织编码
data_rx = data_rx.de_interleaver(data_rx.interleaved, code_rate_rx);
%% DATA 解卷积编码
data_rx = data_rx.de_convolver(data_rx.convoluted, code_rate_rx);
%% DATA 解扰码
data_rx = data_rx.de_scrambler(data_rx.scrambled);
%% DATA 分析

data_tx
data_rx

%% DATA 检测发送与接收内容差异
%TODO ABSTRACT THIS AS PROPERTIES AND METHODS OF TASK
xor_data = xor(data_tx.bin,data_rx.bin);
ones_data = numel(find(xor_data == 1));
errors_data = ones_data / 24 * 100;
sprintf("\t\t*****\nerror in data field is %f\n\t\t*****", errors_data)
