%
% classdef PPDU
%
% Author: Zhao Yanbo (zhaoyanbo@email.com)
% Date:    Spring 2024
% Course:  Communication Engineering Program Design II
%
% Properties:
%
%   preamble - Preamble object
%   signal   - Signal object
%   data     - Data object
%   content  - Combined content of preamble, signal, and data
%
% Methods:
%
%   function obj = PPDU(preamble, signal, data)
%       % PPDU Construct an instance of this class
%       %   Detailed explanation goes here
%   end
%
classdef PPDU
    properties
        preamble
        signal
        data
        content
    end
    methods

        function obj = PPDU(preamble, signal, data)
            obj.preamble = preamble;
            obj.signal = signal;
            obj.data = data;
            obj.content = [preamble.content signal.cyclic_prefixed data.cyclic_prefixed];
        end

    end
end
