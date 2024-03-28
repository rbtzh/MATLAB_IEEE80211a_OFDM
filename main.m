clear
clc

addpath(genpath('./lib'))

disp('#############################################');
disp("802.11a OFDM Simulation implemented in MATLAB");
disp('#############################################\n\n');

%% 初始化
% Get some essential value from user:
[trans_rate,message,scrambling_seed] = showDialog();


%% 信源 MAC地址配置 MAC层成帧 SERVICE FIELD生成
% Do someting rate specified configuration
[RATE, code_rate, Pad_Bits, Tail, SERVICE] = rateHandler(trans_rate);

% raw data without modulation
    % PSDU
    % psdu.bin
    % psdu.length
psdu = PSDU(message);

% DATA used in PPDU
    % data.bin  
data = DATA(SERVICE, psdu.bin, Tail, Pad_Bits);

%% DATA 加扰
data = data.scrambler(data.bin, scrambling_seed);

%% DATA 卷积编码
%TODO change the implementation of this
data = data.convolver_tx(data.scrambled, code_rate);

%% DATA 交织编码
data = data.interleaver_tx(data.convoluted, code_rate);

%% DATA 调制
data = data.modulator(data.interleaved, code_rate);

%% DATA 添加导频
data = data.pilot(data.modulated);

%% DATA 进行 IFFT64 运算
data = data.IFFT64(data.piloted);

%% DATA 添加循环前缀
data = data.cyclic_prefix(data.ifft64ed);

%% SIGNAL FIELD生成
% SIGNAL used in PPDU
signal = SIGNAL(RATE, psdu.length);

%% SIGNAL 卷积编码

%% SIGNAL 交织编码
%% SIGNAL 调制
%% SIGNAL 添加导频
%% SIGNAL 进行 IFFT64 运算
%% SIGNAL 添加循环前缀

%% PREAMBLE产生
% Preamable used in PPDU
    % preamable.short
    % preamable.long
    % preamable.full
preamable = PREAMBLE();

