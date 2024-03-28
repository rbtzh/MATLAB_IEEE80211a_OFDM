%函数功能：产生signal字段
function SIGNAL = signal_example(len_psdu,RATE) 
Reserved = 0;                                   %保留位 1bit
dec = dec2bin(len_psdu);                        %dec2bin:将十进制整数转换为其二进制表示形式,输出参数dec是一个字符向量
zero1 = zeros(1, 12 - length(dec));             %确定length字段中0的个数
binRate = str2num(dec(:))';                     %str2num:将字符数组或字符串转换为数值数组
LENGTH = [zero1 binRate];                       %长度位 12bit
Parity = 0;                                     %奇偶校验位 1bit
Tail = zeros(1,6);                              %尾比特 6bit
SIGNAL = [RATE Reserved LENGTH Parity Tail];    %signal字段=速率位+保留位+长度位+奇偶校验位+尾比特

end