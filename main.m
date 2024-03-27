function M = main()
clc
disp("Please choose transmitting rate:")
flag = input('1. 6mbps\n2. 36mbps TX\n')
preamble = Preamble();
