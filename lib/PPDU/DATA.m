classdef DATA
    %DATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bin
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

    end
end

