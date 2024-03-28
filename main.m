clear
clc

addpath(genpath('./lib'))

disp('#############################################');
disp("802.11a OFDM Simulation implemented in MATLAB");
disp('#############################################\n\n');

% Get some essential value from user:
[trans_rate,message,scrambling_seed] = showDialog();

% Do someting rate specified configuration
[RATE, code_rate, Pad_Bits, Tail, SERVICE ] = rateHandler(trans_rate);

% raw data without modulation
    % PSDU
    % psdu.bin
    % psdu.length
psdu = PSDU(message);

% DATA used in PPDU
    % data.bin  
data = DATA(SERVICE, psdu.bin, Tail, Pad_Bits);

% Preamable used in PPDU
    % preamable.short
    % preamable.long
    % preamable.full
preamable = PREAMBLE();
