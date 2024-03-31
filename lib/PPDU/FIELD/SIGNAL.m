%
% classdef SIGNAL < FIELD
%
% SIGNAL field in PPDU
%
% Author: Zhao Yanbo (zhaoyanbo@email.com)
% Date:    Spring 2024
% Course:  Communication Engineering Program Design II
%
% Properties (Access = protected):
%
%   rate     - Rate of the signal
%   reserved - Reserved value
%   len      - Length of the signal
%   parity   - Parity value
%   tail     - Tail data
%
% Methods:
%
%   function obj = SIGNAL()
%       % SIGNAL Constructor
%       %   Detailed explanation goes here
%   end
%
classdef SIGNAL < FIELD
    % SIGANl field in PPDU

    properties (Access = protected)
        rate
        reserved = 0
        len
        parity = 0
        tail = zeros(1, 6)
    end

    methods
        function obj = SIGNAL()
        end
    end
end
