function out = BPSK(in)

    table=exp(1i*[0 -pi]);  % 生成BPSK序列(欧拉公式)
    table=table([1 0]+1); % bpsk符号的格雷码映射模式 
    inp=in;
    out=table(inp+1); %将传输的比特映射为bpsk符号 
    r = real(out);
    l = imag(out);
    scatter(r,l,'*');
end