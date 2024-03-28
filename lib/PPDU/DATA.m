classdef DATA
    %DATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bin
        scrambled
    end
    
    methods
        function obj = DATA(SERVICE, PSDU, Tail, Pad_Bits)
            %DATA Construct an instance of this class
            %   Detailed explanation goes here
            DATA1 = [SERVICE PSDU Tail Pad_Bits];                                  %data段=业务位16bit+PSDU+尾比特6bit+填充位
            number_bit=ceil(length(DATA1)/24);
            Pad_Bits=zeros(1,number_bit*24-length(DATA1));
            obj.bin = [SERVICE PSDU Tail Pad_Bits];
        end
        function obj = scrambler(obj, in, seed) 
            data_length=length(in);
            
            for i =1:127                                                               %产生加扰序列
                Temp = xor(seed(4),seed(7));
                seed = [Temp,seed(1,1:6)];
                scramb_temp(i) = Temp;      
            end
            out_temp=repmat(scramb_temp,1,ceil(data_length/length(scramb_temp)));                %repmat复制和平铺矩阵,ceil向上取整
            scramb_temp=out_temp(1:data_length);                                           %将输入数据的长度和扰码序列长度匹配
            obj.scrambled=xor(in,scramb_temp);  
        end
    end
end

