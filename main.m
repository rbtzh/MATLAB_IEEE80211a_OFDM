clear
% clc

addpath(genpath('./lib'))

disp('#############################################');
disp("802.11a OFDM Simulation implemented in MATLAB");
disp('#############################################');

[trans_rate,message,scrambling_seed, snr] = UTILS.show_dialog();

tic
task = TASK(trans_rate,message,scrambling_seed, snr);
task = task.run();
[error_signal, error_data] = task.analyze(true);
toc