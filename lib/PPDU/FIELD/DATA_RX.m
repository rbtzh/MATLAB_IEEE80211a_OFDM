classdef DATA_RX < DATA
    %DATA_RX 此处显示有关此类的摘要
    %   此处显示详细说明
    
    methods
        function obj = DATA_RX(in)
            obj.modulated = in;
        end
        function obj = de_modulator(obj, in, code_rate)
            if code_rate==1/2
                obj.interleaved = obj.DE_BPSK(in);
            elseif code_rate==3/4
                obj.interleaved = obj.DE_QAM16(in);
            end
        end
        function obj = de_interleaver(obj, in, code_rate)
            if code_rate == 3/4
                block_size=192; %相应速率对应的每OFDM符号的编码比特数 6M对应48；36m对应192
            else 
                block_size=48; %相应速率对应的每OFDM符号的编码比特数 6M对应48；36m对应192
            end
        
            s = max(block_size/96,1);%Max（每子载波的编码比特数/2,1），其中每子载波的编码比特数= block_size/48
            perm_patt = s*floor((0:block_size-1)/s)+mod((0:block_size-1)+floor(16*(0:block_size-1)/block_size),s);
            deintlvr_patt = 16*perm_patt - (block_size-1)*floor(16*perm_patt/block_size);
            single_deintlvr_patt = deintlvr_patt + 1;
            block_bits = reshape(in,block_size,length(in)/block_size);
            %将输入数据按块大小分组，一个块分组为1列，共分为length(in_bits)/block_size列
            %192行n列
            out_bits(single_deintlvr_patt,:) = block_bits; %将各个矩阵块的比特与置换后位置对应
            obj.convoluted = out_bits(:).';%串行输出
        end
        function obj = de_convolver(obj, in, code_rate)
            
            %插入哑元0将信号还原成为编码速率为1/2的卷积码进行解码
            if code_rate==3/4
              
               TRELLIS=poly2trellis([3 3 3],[7 7 0 4;3 2 7 4;0 2 3 7]);  %实现3输入4输出的卷积编码器
            elseif code_rate==1/2
            
               TRELLIS=poly2trellis(7,[133,171]);    %实现1输入2输出的卷积编码器
            else
               error('Undefined convolutional code rate');
            end
            
             % 使用Viterbi算法解卷积
             % 原型decoded =vitdec(code,trellis,tblen,opmode,dectype)；
             % trellis：网格表，用来规定我们使用的卷积编码的规则
             % tblen：指定回溯深度的正整数标量
             % opmode：译码器的工作模式及其对相应编码器工作的假设
             % dectype：用于指明译码器的决策类型
             CODE=in;
             TBLEN=7;
             OPMODE='trunc';%假设编码器的初始状态为全“0” ；解码器用最佳度量从状态回溯。这种方式不产生延时               
             DECTYPE='hard';%硬判决 二进制输入
             obj.scrambled = vitdec(CODE,TRELLIS,TBLEN,OPMODE,DECTYPE);
        end
        function obj = de_scrambler(obj, in)
            s=in(1:7);
            x1=xor(s(1,3),s(1,7));
            x2=xor(s(1,2),s(1,6));
            x3=xor(s(1,1),s(1,5));
            x4=xor(x1,s(1,4));
            seed=[x1,x2,x3,x4,xor(x2,s(1,3)),xor(x3,s(1,2)),xor(x4,s(1,1))];
            
            data_length=length(in);
            scramb_temp = zeros(1,127);
            for i =1:127                                                   
                Temp = xor(seed(4),seed(7));
                seed = [Temp,seed(1,1:6)];
                scramb_temp(i) = Temp;      
            end
            out_temp=repmat(scramb_temp,1,ceil(data_length/length(scramb_temp)));
            scramb_temp=out_temp(1:data_length);
            obj.bin=xor(in,scramb_temp);
        end
    end
end

