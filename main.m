clear
clc

addpath(genpath('./lib'))

disp('#############################################');
disp("802.11a OFDM Simulation implemented in MATLAB");
disp('#############################################');

%% 初始化
% initialization
% Get some essential value from user using dialog
[trans_rate,message,scrambling_seed] = INITUTILS.show_dialog();


%% 信源 MAC地址配置 MAC层成帧 SERVICE FIELD生成
% calculation of MAC layer data passed to PHY layer
% Do someting rate specified configuration
[RATE, code_rate, Pad_Bits, Tail, SERVICE] = INITUTILS.rate_handler(trans_rate);

%% 生成 PSDU
% PSDU construction
psdu = PSDU(message);

%% 生成 DATA 段
% DATA field/object construction
data = DATA(SERVICE, psdu.bin, Tail, Pad_Bits);

%% DATA 加扰
% DATA field scrambling
data = data.scrambler(data.bin, scrambling_seed);

%% DATA 卷积编码
% DATA field convolution encoding
data = data.convolver_tx(data.scrambled, code_rate);

%% DATA 交织编码
% DATA field interleaved encoding
data = data.interleaver_tx(data.convoluted, code_rate);

%% DATA 调制
% DATA field Modulation
data = data.modulator(data.interleaved, code_rate);

%% DATA 添加导频
% DATA field add pilot 
data = data.pilot(data.modulated);

%% DATA 进行 IFFT64 运算
% DATA field do IFFT64 calculation
data = data.IFFT64(data.piloted);

%% DATA 添加循环前缀
% DATA field add cyclic prefix
data = data.cyclic_prefix(data.ifft64ed);

%% 生成 SIGNAL 段
% SIGNAL field/object construction
signal = SIGNAL(RATE, psdu.length);

%% SIGNAL 卷积编码
% SIGNAL field convolution encoding
signal = signal.convolver_tx(signal.bin);

%% SIGNAL 交织编码
% SIGNAL field interleaved encoding
signal = signal.interleaver_tx(signal.convoluted);

%% SIGNAL 调制
% SIGNAL field Modulation
signal = signal.modulator(signal.interleaved);

%% SIGNAL 添加导频
% SIGNAL field add pilot 
signal = signal.pilot(signal.modulated);

%% SIGNAL 进行 IFFT64 运算
% SIGNAL field do IFFT64 calculation
signal = signal.IFFT64(signal.piloted);

%% SIGNAL 添加循环前缀
% SIGNAL field add cyclic prefix
signal = signal.cyclic_prefix(signal.ifft64ed);

%% 生成 PREAMBLE 段
% PREAMABLE field/object construction
preamable = PREAMBLE();

%% 生成 PPDU
% PPDU construction
ppdu = PPDU(preamable, signal, data);
