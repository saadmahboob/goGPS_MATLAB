function [tropocorr] = err_tropo(elev, h)

% SYNTAX:
%   [tropocorr] = err_tropo(elev, h);
%
% INPUT:
%   elev = satellite elevation
%   h = ellipsoid height
%
% OUTPUT:
%   tropocorr = tropospheric correction
%
% DESCRIPTION:
%   Computation of the pseudorange correction due to tropospheric refraction.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 alpha
%
% Copyright (C) 2009 Laboratorio di Geomatica, Polo Regionale di Como, Politecnico di Milano, Italy
%
%----------------------------------------------------------------------------------------------

elev=abs(elev);

%pressure [mbar]
Pr = 1013.25; 
%temperature [K]
Tr = 291.15;
%numerical constants for the algorithm [-] [m] [mbar]
Hr = 50.0;
h_a = [0,500,1000,1500,2000,2500,3000,4000,5000];
B_a = [1.156,1.079,1.006,0.938,0.874,0.813,0.757,0.654,0.563];

%Saastamoinen algorithm
P = Pr * (1-0.0000226*h)^5.225;

T = Tr - 0.0065*h;

H = Hr*exp(-0.0006396*h);

i=1;

while i < 9
    if (h >= h_a(i)) & (h <= h_a(i+1))
        m = (B_a(i+1) - B_a(i)) / (h_a(i+1) - h_a(i));
        B = B_a(i) + m*(h - h_a(i));
    end
    i = i+1;
end

e= 0.01*H*exp(-37.2465+0.213166*T-0.000256908*T^2);

%tropospheric error
tropocorr = ((0.002277/sin(elev*pi/180)) * (P - (B/(tan(elev*pi/180))^2)) + (0.002277/sin(elev*pi/180)) * (1255/T + 0.05) * e);