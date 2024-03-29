classdef DATA_TX < DATA
    %DATA_TX is the representation of data field used in transmittion
    %   
    
    methods
        function obj = DATA_TX(SERVICE, PSDU, Tail, Pad_Bits)
            %DATA Construct an instance of this class
            %   Detailed explanation goes here
            DATA1 = [SERVICE PSDU Tail Pad_Bits];
            number_bit=ceil(length(DATA1)/24);
            Pad_Bits=zeros(1,number_bit*24-length(DATA1));
            obj.bin = [SERVICE PSDU Tail Pad_Bits];
        end

        function obj = scrambler(obj, in, seed) 
            data_length=length(in);
            
            scramb_temp = zeros(1,127);
            for i =1:127                                                   
                Temp = xor(seed(4),seed(7));
                seed = [Temp,seed(1,1:6)];
                scramb_temp(i) = Temp;      
            end

            out_temp=repmat(scramb_temp,1,ceil(data_length/length(scramb_temp)));
            scramb_temp=out_temp(1:data_length);
            obj.scrambled=xor(in,scramb_temp);  
        end

        function obj = convolver_tx(obj, in, code_rate)
            
            ConvCodeGenPoly=[1 0 1 1 0 1 1;1 1 1 1 0 0 1 ];
            
            number_rows = size(ConvCodeGenPoly, 1);
            number_bits = size(ConvCodeGenPoly,2)+length(in)-1;
            uncoded_bits = zeros(number_rows, number_bits);
            
            for row=1:number_rows
            
             uncoded_bits(row,1:number_bits)=rem(conv(in*1, ConvCodeGenPoly(row,:)),2);
             
            end
            
            coded_bits=uncoded_bits(:);
            coded_bits1=coded_bits(:).';
                if code_rate == 3/4
                    punc_patt=[1 2 3 6];
                    punc_patt_size = 6;
                else 
                    punc_patt=[1 2 3 4 5 6];
                    punc_patt_size = 6;
                end
            coded_bits=coded_bits1(1:length(coded_bits1)-12);
            num_rem_bits = rem(length(coded_bits), punc_patt_size);
            
            puncture_table = reshape(coded_bits(1:length(coded_bits)-num_rem_bits), punc_patt_size, fix(length(coded_bits)/punc_patt_size));

            tx_table = puncture_table(punc_patt,:);
            

            rem_bits = coded_bits(length(coded_bits)-num_rem_bits+1:length(coded_bits));
            rem_punc_patt = find(punc_patt<=num_rem_bits);
            rem_punc_bits=zeros(1,num_rem_bits);
            rem_punc_bits(rem_punc_patt) = rem_bits(rem_punc_patt);
            
            punctured_bits = [tx_table(:)' rem_punc_bits];
            obj.convoluted=punctured_bits;
        end

        function obj =interleaver_tx(obj, in,code_rate)
            
            if code_rate == 3/4
                block_size=192; %相应速率对应的每OFDM符号的编码比特数 6M对应48；36m对应192
            else 
                block_size=48; %相应速率对应的每OFDM符号的编码比特数 6M对应48；36m对应192
            end
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

        function obj = modulator(obj, in, code_rate)
            if code_rate==1/2
                obj.modulated = obj.BPSK(in);                                  %映射
            elseif code_rate==3/4
                obj.modulated = obj.QAM16(in);                                %QAM
            end
        end
    end
end

