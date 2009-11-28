function [data] = decode_1011(msg)

% SYNTAX:
%   [data] = decode_1011(msg)
%
% INPUT:
%   msg = binary message received from the master station
%
% OUTPUT:
%   data = cell-array that contains the 1011 packet information
%          1.1) DF002 = message number = 1011
%          2.1) DF003 = Reference station ID
%          2.2) DF034 = GLONASS epoch time tk (ms)
%          2.3) DF005 = Syncronous GNSS flag (0 = no GNSS obs. for the same epoch, 1 = other GNSS obs.)
%          2.4) DF035 = N� of GLONASS satellite signal processed
%          2.5) DF036 = GLONASS Divergence-free Smoothing Indicator (0 = not used, 1 = used)
%          2.6) DF037 = GLONASS Smoothing Interval - flag (see table 3.4-4 - RTCM manual)
%          3.1) DF039 = GLONASS L1 Code Indicator (0 = C/A, 1 = P)
%          3.2) DF041 = GLONASS L1 pseudorange (m)
%          3.3) DF042 = (DF041*0.02 + DF017*0.0005) / lambda1 = GLONASS L1 PhaseRange � L1 Pseudorange (m)
%          3.4) DF043 = GLONASS L1 Lock Time Indicator (if there is a cycle slip it is set to 0)
%          3.5) DF046 = GLONASS L2 Code Indicator (0 = C/A, 1 = P, 2-3 reserved)
%          3.6)(DF041*0.02 + DF047*0.02) = GLONASS L2-L1 Pseudorange Difference (m)
%          3.7)(DF041*0.02 + DF048*0.0005) = GLONASS L2 PhaseRange � L1 Pseudorange (m)
%          3.8) DF049 = GLONASS L2 Lock Time Indicator(if there is a cycle slip it is set to 0)
%          3.9)(DF040 - 7) * 0.5625 + 1602.0 = frequency vector on L1 [MHz]
%          3.10)(DF040 - 7) * 0.4375 + 1246.0 = frequency vector on L2 [MHz]
%              
% DESCRIPTION:
%   RTCM format 1011 message decoding.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 alpha
%
% Copyright (C) 2009 Mirko Reguzzoni*, Eugenio Realini**, Sara Lucca*
%
% * Laboratorio di Geomatica, Polo Regionale di Como, Politecnico di Milano, Italy
% ** Media Center, Osaka City University, Japan
%----------------------------------------------------------------------------------------------
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%----------------------------------------------------------------------------------------------

%light velocity
global v_light

%message pointer initialization
pos = 1;

%output variable initialization
data = cell(3,1);
data{1} = 0;
data{2} = zeros(6,1);
data{3} = zeros(32,10);

%message number = 1020
DF002 = bin2dec(msg(pos:pos+11)); pos = pos + 12;

%Reference station ID
DF003 = bin2dec(msg(pos:pos+11)); pos = pos + 12;

%GLONASS epoch time tk (ms)
DF034 = bin2dec(msg(pos+26)); pos = pos + 27;

%Syncronous GNSS flag
DF005 = bin2dec(msg(pos)); pos = pos + 1;

%Number of GLONASS satellite signal processed
DF035 = bin2dec(msg(pos:pos+4)); pos = pos + 5;

%GLONASS Divergence-free Smoothing Indicator
DF036 = bin2dec(msg(pos)); pos = pos + 1;

%GLONASS Smoothing Interval
DF037 = bin2dec(msg(pos:pos+2)); pos = pos + 3;

%output data save
data{1} = DF002;
data{2}(1) = DF003;
data{2}(2) = DF034;
data{2}(3) = DF005;
data{2}(4) = DF035;
data{2}(5) = DF036;
data{2}(6) = DF037;

%number of satellites
NSV = data{2}(4);

%data decoding for each satellite
for i = 1 : NSV

    %GLONASS satellite ID
    SV = bin2dec(msg(pos:pos+5)); pos = pos + 6;

    %GLONASS L1 code indicator
    DF039 = bin2dec(msg(pos)); pos = pos + 1;

    %GLONASS Satellite Frequency Channel Number
    DF040 = bin2dec(msg(pos:pos+4)); pos = pos + 5;

    %GLONASS L1 pseudorange
    DF041 = bin2dec(msg(pos:pos+24)) * 0.02; pos = pos + 25;

    %GLONASS L1 PhaseRange � L1 Pseudorange
    DF042 = twos_complement(msg(pos:pos+19)) * 0.0005;  pos = pos + 20;

    %GLONASS L1 Lock Time Indicator
    DF043 = bin2dec(msg(pos:pos+6)); pos = pos + 7;

     %---------------------------------------------------------

    %GLONASS L2 Code Indicator 
    DF046 = bin2dec(msg(pos:pos+1)); pos = pos + 2;

    %GLONASS L2-L1 Pseudorange Difference
    DF047 = twos_complement(msg(pos:pos+13)) * 0.02; pos = pos + 14;

    %GLONASS L2 PhaseRange � L1 Pseudorange (m)
    DF048 = twos_complement(msg(pos:pos+19)) * 0.0005; pos = pos + 20;

    %GLONASS L2 Lock Time Indicator
    DF049 = bin2dec(msg(pos:pos+6)); pos = pos + 7;

    %L1 carrier frequency [MHz]
    data{3}(SV,9) = (DF040 - 7) * 0.5625 + 1602.0;

    %L2 carrier frequency [MHz]
    data{3}(SV,10) = (DF040 - 7) * 0.4375 + 1246.0;

    %output data save
    data{3}(SV,1)  = DF039;
    data{3}(SV,2)  = DF041;
    data{3}(SV,3)  = (data{3}(SV,2) + DF042) * data{3}(SV,9) * 1e6 / v_light;
    data{3}(SV,4)  = DF043;
    data{3}(SV,5)  = DF046;
    data{3}(SV,6)  = (data{3}(SV,2) + DF047);
    data{3}(SV,7)  = (data{3}(SV,2) + DF048) * data{3}(SV,10) * 1e6 / v_light; 
    data{3}(SV,8)  = DF049;

end