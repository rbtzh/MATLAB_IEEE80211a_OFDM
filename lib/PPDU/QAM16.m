function out = QAM16(in)
m=1;
full_len = length(in);
for k=-3:2:3
  for l=-3:2:3
     table(m) = (k+1i*l)/sqrt(10); % 功率归一化（1/sqrt(10)）
     m=m+1;
  end
end
table=table([0 1 3 2 4 5 7 6 12 13 15 14 8 9 11 10]+1); % 8-psk符号的格雷码映射模式
inp=reshape(in,4,full_len/4);
out=table([8 4 2 1]*inp+1);  %将传输的比特映射为16个QAM符号
r = real(out);
l = imag(out);
scatter(r,l,'*');
hold on
grid on
axis([-1 1,-1 1]);
xlabel('I');
ylabel('Q');
title('16-QAM星座图');
