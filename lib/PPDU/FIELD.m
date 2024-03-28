classdef FIELD
    %FIELD superclass of PPDU Fields
    %   This should be the superclass of class DATA and SIGNAL
    
    properties
        bin
        convoluted
        interleaved
        modulated
        piloted
        ifft64ed
        cyclic_prefixed
    end
    
    methods
        function obj = FIELD()
        end
        
        function obj = pilot(obj, in)
            PilotScramble=[1 1 1 1 -1 -1 -1 1 -1 -1 -1 -1 1 1 -1 1 -1 -1 1 1 -1 1 1 -1 1 1 1 1 ...
                  1 1 -1 1 1 1 -1 1 1 -1 -1 1 1 1 -1 1 -1 -1 -1 1 -1 1 -1 -1 1 -1 -1 1 1 1 1 1 -1 -1 1 ...
                  1 -1 -1 1 -1 1 -1 1 1 -1 -1 -1 1 1 -1 -1 -1 -1 1 -1 -1 1 -1 1 1 1 1 -1 1 -1 1 -1 1 -1 ...
                  -1 -1 -1 -1 1 -1 1 1 -1 1 -1 1 1 1 -1 -1 1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1];%导频伪随机序列
            NumDataSubc=48;% 数据子载波数
            NumSubc=52;%子载波数
            DataSubcPatt=[1:5 7:19 21:26 27:32 34:46 48:52]';%数据子载波的位置
            PilotSubcPatt=[6 20 33 47]';%导频子载波的位置
            NumPilotSubc=4;% 导频子载波数
            PilotSubcSymbols=[1;1;1;-1];%导频子载波的符号
            
            n_mod_syms = size(in,2);%发送的映射调制符号数
            n_ofdm_syms = ceil(n_mod_syms/NumDataSubc);%发送的OFDM符号数
            in=[in zeros(1,n_ofdm_syms*NumDataSubc-n_mod_syms)];
            
            %导频加扰模式 
            scramble_patt = repmat(PilotScramble,1,ceil(n_ofdm_syms/length(PilotScramble)));%重复导频扰码，使得其长度至少与OFDM符号数一样
            scramble_patt = scramble_patt(1:n_ofdm_syms);%截取与OFDM符号数个导频扰码序列
            
            mod_ofdm_syms = zeros(NumSubc, n_ofdm_syms);
            mod_ofdm_syms(DataSubcPatt,:) = reshape(in, NumDataSubc, n_ofdm_syms);%将映射调制符号mod_syms按分组插入NumDataSubc个数据子载波中
            
            %将导频子载波符号序列进行扰码后插入相应导频子载波位置上
            mod_ofdm_syms(PilotSubcPatt,:) = repmat(scramble_patt, NumPilotSubc,1).*repmat(PilotSubcSymbols, 1, n_ofdm_syms);
            %导频插入后的数据输出
            obj.piloted = mod_ofdm_syms(:).';
        end
        function obj = IFFT64(obj, in)
            %IFFT64：信号由频域变换到时域
            UsedSubcIdx=[7:32 34:59]';%使用的子载波索引
            NumSubc=52;%子载波数
            
            %OFDM符号数
            num_symbols =size(in, 2)/NumSubc;
            
            %将数据加到相应子载波上，并在未使用的子载波上补0
            syms_into_ifft = zeros(64, num_symbols);
            syms_into_ifft(UsedSubcIdx,:) = reshape(in(:),NumSubc, num_symbols);
             
            %数据位置置换
            resample_patt=[33:64 1:32];
            syms_into_ifft(resample_patt,:) = syms_into_ifft;
               
            % 变换到时域
            time_syms = zeros(1,num_symbols*64);%初始化time_syms
            ifft_out = ifft(syms_into_ifft);
            time_syms(1,:) = ifft_out(:).';
            obj.ifft64ed = time_syms;
        end
        function obj = cyclic_prefix(obj, time_syms)
            num_symbols = size(time_syms, 2)/64;      %需要传输的符号数（每符号有64数据码元）
            time_signal = zeros(1, num_symbols*80);   %产生时域信号的初始状态；
            
            % 增加循环前缀
            symbols = reshape(time_syms(:), 64, num_symbols);
            tmp_syms = [symbols(49:64,:); symbols];    %取一个符号后16bit
            tmp_syms(1,:)=tmp_syms(1,:)*0.5;           %对符号的首尾进行加窗处理
            tmp_syms_end(1,:)=symbols(1,:)*0.5;
            
            tmp_syms(1,2:num_symbols)=tmp_syms(1,2:num_symbols)+tmp_syms_end(1:num_symbols-1);
            time_signal(:) = tmp_syms(:).';
            obj.cyclic_prefixed = time_signal;
        end
    end
end

