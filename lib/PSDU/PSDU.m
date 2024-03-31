%
% classdef PSDU
%
% PSDU Summary of this class goes here
%   Detailed explanation goes here
%
% Author: Zhao Yanbo (zhaoyanbo@email.com)
% Date:    Spring 2024
% Course:  Communication Engineering Program Design II
%
% Properties:
%
%   bin    - Binary representation of the message
%   length - Length of the binary representation
%
% Methods:
%
%   function obj = PSDU(message)
%       % PSDU Construct an instance of this class
%       %   Detailed explanation goes here
%   end
%
classdef PSDU
    % PSDU Summary of this class goes here
    %   Detailed explanation goes here

    properties
        bin
        length
    end

    methods

        function obj = PSDU(message)
            % PSDU Construct an instance of this class
            %   Detailed explanation goes here
            IN = abs(message);
            PSDU_vertical = de2bi(IN);
            obj.bin = PSDU_vertical(:)';
            obj.length = length(obj.bin);
        end

    end
end
