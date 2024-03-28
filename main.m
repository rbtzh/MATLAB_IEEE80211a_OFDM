clear
clc
disp('#############################################');
disp("802.11a OFDM Simulation implemented in MATLAB");
disp('#############################################\n\n');
[rate,message,scrambling_seed] = showDialog();
preamble = Preamble();