function [ERP, found] = load_ERP(filename, time)

% SYNTAX:
%   [ERP, found] = load_ERP(filename, time);
%
% INPUT:
%   filename = ERP filename (including path) [string]
%   time = GPS time to identify the time range of interest [vector]
%
% OUTPUT:
%   ERP = struct containing ERP data
%   found = flag to check if the required file was found
%
% DESCRIPTION:
%   Tool for loading .erp files: Earth rotation parameters.

%--- * --. --- --. .--. ... * ---------------------------------------------
%               ___ ___ ___
%     __ _ ___ / __| _ | __
%    / _` / _ \ (_ |  _|__ \
%    \__, \___/\___|_| |___/
%    |___/                    v 0.5.1 beta 3
%
%--------------------------------------------------------------------------
%  Copyright (C) 2009-2017 Mirko Reguzzoni, Eugenio Realini
%  Written by:
%  Contributors:     ...
%  A list of all the historical goGPS contributors is in CREDITS.nfo
%--------------------------------------------------------------------------
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------
% 01100111 01101111 01000111 01010000 01010011
%--------------------------------------------------------------------------

warning off %#ok<WNOFF>

found = 0;
ERP = [];
MJD = [];
Xpole = [];
Ypole = [];
UT1_UTC = [];
LOD = [];
for f = 1 : length(filename)
    fid = fopen(filename{f},'rt');
    
    if fid == -1
        return
    end
    
    l=fgetl(fid);
    i=1;
    
    %check version
    if ~strcmp(l, 'version 2')
        %wrong version
        fclose(fid);
        return
    end
    
    while isempty(strfind(l,'  MJD'));
        if l==-1
            fclose(fid);
            return
        end
        l=fgetl(fid);
        i=i+1;
    end
    i=i+1;
    fseek(fid, 0, 'bof');
    
    % [MJD,Xpole,Ypole,UT1_UTC,LOD,Xsig,Ysig,UTsig,LODsig,Nr,Nf,Nt,Xrt,Yrt,Xrtsig,Yrtsig] = textread(filename,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f','delimiter',' ','headerlines', i);
    
    ERP_data = textscan(fid,'%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f','headerlines',i);
    
    if (isempty(ERP_data{1}))
        fclose(fid);
        return
    else
        found = 1;
    end
    
    MJD = [MJD; ERP_data{1}]; %#ok<*AGROW>
    Xpole = [Xpole; ERP_data{2}];
    Ypole = [Ypole; ERP_data{3}];
    UT1_UTC = [UT1_UTC; ERP_data{4}];
    LOD = [LOD; ERP_data{5}];
end

jd = MJD + 2400000.5;
[gps_week, gps_sow, ~] = jd2gps(jd);
[ERP_time] = weektow2time(gps_week, gps_sow ,'G');

if ~any(ERP_time <= max(time) | ERP_time >= min(time))
    % no suitable epochs found in erp file
    fclose(fid);
    ERP = [];
    return
end
    
% assign ERP values and compute rates (@ epoch of the first epoch of orbits
% ERP.t0 = min(time);

%correct MJD with the length of day
for i = 2 : length(ERP_time)
    ERP_time(i)=ERP_time(i)+(LOD(i-1)*0.1e-6);
end

ERP.t = ERP_time;
ERP.Xpole = Xpole;
ERP.Ypole = Ypole;

% % compute rates
% a = polyfit(ERP_time,Xpole,1); %#ok<*ASGLU>
% ERP.X0 = polyval(a,ERP.t0);
% ERP.Xrt = a(1)*86400;
% 
% a = polyfit(ERP_time,Ypole,1);
% ERP.Y0 = polyval(a,ERP.t0);
% ERP.Yrt = a(1)*86400;
% 
% a = polyfit(ERP_time,UT1_UTC,1);
% ERP.UT1_UTC0 = polyval(a,ERP.t0);
% ERP.UT1_UTCrt = a(1)*86400;
% 
% ERP.units.X0Y0='10**-6"';
% ERP.units.XYrt='10**-6"/d';
% ERP.units.UT1_UTC0='0.1 usec';
% ERP.units.UT1_UTCrt='0.1 usec/d';

fclose(fid);
