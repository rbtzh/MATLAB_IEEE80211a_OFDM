classdef SIGNAL
    %SIGANl segment in PPDU
    
    properties
        bin
        convoluted
        interleaved
        modulated
        piloted
        ifft64ed
        cyclic_prefixed
    end
    properties(Access=private)
        rate
        reserved = 0
        len
        parity = 0
        tail = zeros(1,6)
    end
    
    methods
        function obj = SIGNAL(rate, PSDU_length)
            obj.rate = rate;
            dec = dec2bin(PSDU_length);
            zero1 = zeros(1, 12 - length(dec));
            binRate = str2num(dec(:))'; %#ok<ST2NM>
            obj.len = [zero1 binRate];
            obj.bin = [obj.rate obj.reserved obj.len obj.parity obj.tail];
        end
        function obj = convolver_tx(obj, in)%加扰后的bit流
            
            ConvCodeGenPoly=[1 0 1 1 0 1 1;1 1 1 1 0 0 1 ];%生成多项式推出
            
            number_rows = size(ConvCodeGenPoly, 1);%行数
            number_bits = size(ConvCodeGenPoly,2)+length(in)-1;%列数+输入比特长度-1
            uncoded_bits = zeros(number_rows, number_bits);%零初始0 存储输出卷积码
            
            for row=1:number_rows
            
             uncoded_bits(row,1:number_bits)=rem(conv(in*1, ConvCodeGenPoly(row,:)),2);
             %将扰码输出的结果和g0卷积后在对2取余得到X1(对2取余使结果保证为二进制)
             %将扰码输出的结果和gl卷积后在对2余得到X2
             %两行结果放入预留的全0矩阵中
             
            end
            
            coded_bits=uncoded_bits(:);
            coded_bits1=coded_bits(:).';
            %打孔删余实现不同编码率  提高编码速率
            %   code_rate=3/4;
            %   punc_patt=[1 2 3 6];
            %   punc_patt_size = 6;
            
            % code_rate=1/2;
            punc_patt=[1 2 3 4 5 6];
            punc_patt_size = 6;
            
            coded_bits=coded_bits1(1:length(coded_bits1)-12);%删去数组中非卷积得到的0 %（7-1）*2
            num_rem_bits = rem(length(coded_bits), punc_patt_size);%取余，保证6n个数
            
            puncture_table = reshape(coded_bits(1:length(coded_bits)-num_rem_bits), punc_patt_size, fix(length(coded_bits)/punc_patt_size));
            %排列成6行6n列
            tx_table = puncture_table(punc_patt,:);%去掉45行 删余实现编码率3/4
            
            %对不足6位的剩余项也进行打孔操作puncture the remainder bits
            rem_bits = coded_bits(length(coded_bits)-num_rem_bits+1:length(coded_bits));
            rem_punc_patt = find(punc_patt<=num_rem_bits);
            rem_punc_bits=zeros(1,num_rem_bits);
            rem_punc_bits(rem_punc_patt) = rem_bits(rem_punc_patt);
            
            punctured_bits = [tx_table(:)' rem_punc_bits];%一结果都串行输出
            obj.convoluted =punctured_bits;
        end

        function obj = interleaver_tx(obj, in)
            
            block_size=48; %相应速率对应的每OFDM符号的编码比特数 6M对应48；36m对应192   
            Ofdm_=ceil(length(in)/block_size);%向上取整
            Pad0=zeros(1,Ofdm_*block_size-length(in));
            in=[in Pad0];%补0达到192的倍数
            block_bits = reshape(in,block_size,length(in)/block_size);%将输入数据按块大小（编码比特Ncbps）分组，一个块分组为1列，共分为length(in_bits)/block_size列
            
            % 第一步转置后每行的索引
            m_k = block_size/16*mod((0:block_size-1),16)+floor((0:block_size-1)/16);
            
            % 第二步转置后每行的索引
            s = max(block_size/96,1);%Max（每子载波的数据比特数/2,1），其中每子载波的数据比特数= block_size/48
            j_k = s*floor(m_k/s)+mod((m_k+block_size-floor(16*m_k/block_size)),s);
            
            % 完成交织
            idx(j_k+1,:) = block_bits;
            obj.interleaved = idx(:).';
        end
        function obj = modulator(obj, in)
            obj.modulated = BPSK(in);
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

