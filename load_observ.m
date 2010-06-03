function [time_GPS, week_R, time_R, time_M, pr1_R, pr1_M, ph1_R, ph1_M, snr_R, snr_M, pos_M, Eph, ...
          iono, loss_R, loss_M] = load_observ (filerootR, filerootM, wait_dlg)

% SYNTAX:
%   [time_GPS, week_R, time_R, time_M, pr1_R, pr1_M, ph1_R, ph1_M, snr_R, snr_M, pos_M, Eph, ...
%    iono, loss_R, loss_M] = load_observ (filerootR, filerootM, wait_dlg);
%
% INPUT:
%   filerootR = rover dataset
%   filerootM = master dataset
%
% OUTPUT:
%   time_GPS = reference GPS time
%   week_R   = GPS week
%   time_R   = GPS time for the ROVER observations
%   time_M   = GPS time for the MASTER observations
%   pr1_R    = ROVER-SATELLITE code-pseudorange (carrier L1)
%   pr1_M    = MASTER-SATELLITE code-pseudorange (carrier L1)
%   ph1_R    = ROVER-SATELLITE phase observations (carrier L1)
%   ph1_M    = MASTER-SATELLITE phase observations (carrier L1)
%   Eph      = matrix of 29 ephemerides for each satellite
%   iono     = ionosphere parameters
%   loss_R   = flag for the ROVER loss of signal
%   loss_M   = flag for the MASTER loss of signal
%   wait_dlg = optional handler to waitbar figure
%
% DESCRIPTION:
%   Reading and synchronization of two distinct observations datasets saved
%   by goGPS.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 beta
%
% Copyright (C) 2009-2010 Mirko Reguzzoni*, Eugenio Realini**
%
% * Laboratorio di Geomatica, Polo Regionale di Como, Politecnico di Milano, Italy
% ** Graduate School for Creative Cities, Osaka City University, Japan
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

if (nargin == 3)
    waitbar(0.5,wait_dlg,'Reading rover dataset...')
end

%ROVER observations reading
[time_GPS, week_R, time_R, null_time_M, pr1_R, null_pr1_M, ph1_R, null_ph1_M, ...
 snr_R, null_snr_M, null_pos_M, Eph_R, iono] = load_goGPSinput (filerootR); %#ok<ASGLU>

if (nargin == 3)
    waitbar(1,wait_dlg)
end

%-------------------------------------------------------------------------------

if (nargin == 3)
    waitbar(0.5,wait_dlg,'Reading master dataset...')
end

%MASTER observations reading
[null_time_GPS, null_week_R, null_time_R, time_M, null_pr1_R, pr1_M, null_ph1_R, ph1_M, ...
 null_snr_R, snr_M, pos_M, Eph_M] = load_goGPSinput (filerootM); %#ok<ASGLU>

if (nargin == 3)
    waitbar(1,wait_dlg)
end

%-------------------------------------------------------------------------------

waitbar(0.33,wait_dlg,'Synchronizing data...')

if ~isempty(time_R) & ~isempty(time_M)

    %head synchronization
    if (time_R(1) < time_M(1))
        pos = find(time_R < time_M(1));
        time_R(pos)    = [];                       %GPS time
        week_R(pos)    = [];                       %GPS week
        pr1_R(:,pos)   = [];                       %code observations
        ph1_R(:,pos)   = [];                       %phase observations
        snr_R(:,pos)   = [];                       %signal-to-noise ratio
        Eph_R(:,:,pos) = [];                       %ephemerides
        iono(:,pos) = [];                          %ionosphere parameters
    end

    if (time_M(1) < time_R(1))
        pos = find(time_M < time_R(1));
        time_M(pos)    = [];                       %GPS time
        pr1_M(:,pos)   = [];                       %code observations
        ph1_M(:,pos)   = [];                       %phase observations
        snr_M(:,pos)   = [];                       %signal-to-noise ratio
        pos_M(:,pos)   = [];                       %master station position
        Eph_M(:,:,pos) = [];                       %ephemerides
    end

    %tail synchronization
    if (time_R(end) > time_M(end))
        pos = find(time_R > time_M(end));
        time_R(pos)    = [];                       %GPS time
        week_R(pos)    = [];                       %GPS week
        pr1_R(:,pos)   = [];                       %code observations
        ph1_R(:,pos)   = [];                       %phase observations
        snr_R(:,pos)   = [];                       %signal-to-noise ratio
        Eph_R(:,:,pos) = [];                       %ephemerides
        iono(:,pos) = [];                          %ionosphere parameters
    end

    if (time_M(end) > time_R(end))
        pos = find(time_M > time_R(end));
        time_M(pos)    = [];                       %GPS time
        pr1_M(:,pos)   = [];                       %code observations
        ph1_M(:,pos)   = [];                       %phase observations
        snr_M(:,pos)   = [];                       %signal-to-noise ratio
        pos_M(:,pos)   = [];                       %master station position
        Eph_M(:,:,pos) = [];                       %ephemerides
    end

end

%-------------------------------------------------------------------------------

if (nargin == 3)
    waitbar(0.66,wait_dlg)
end

%signal losses
time_GPS = union(time_R,time_M);                     %overall reference time

if ~isempty(time_GPS)

    time_GPS = (time_GPS(1) : 1 : time_GPS(end))';   %GPS time without interruptions

    loss_R = 1 - ismember(time_GPS,time_R);          %losses of signal (ROVER)
    loss_M = 1 - ismember(time_GPS,time_M);          %losses of signal (MASTER)

    if ~isempty(time_R)

        newtime_R = setdiff(time_GPS, time_R);       %ROVER missing epochs
        for i = 1 : length(newtime_R)

            pos = find(time_R == newtime_R(i) - 1);  %position before the "holes"

            time_R = [time_R(1:pos);  newtime_R(i);  time_R(pos+1:end)];
            week_R = [week_R(1:pos);  0;             week_R(pos+1:end)];
            pr1_R  = [pr1_R(:,1:pos)  zeros(32,1)    pr1_R(:,pos+1:end)];
            ph1_R  = [ph1_R(:,1:pos)  zeros(32,1)    ph1_R(:,pos+1:end)];
            snr_R  = [snr_R(:,1:pos)  zeros(32,1)    snr_R(:,pos+1:end)];
            iono   = [iono(:,1:pos)   zeros(8,1)     iono(:,pos+1:end)];

            Eph_R  = cat(3, Eph_R(:,:,1:pos), zeros(29,32,1), Eph_R(:,:,pos+1:end));
        end
    else
        time_R = time_GPS;
        week_R = zeros(1,length(time_GPS));
        pr1_R  = zeros(32,length(time_GPS));
        ph1_R  = zeros(32,length(time_GPS));
        snr_R  = zeros(32,length(time_GPS));
        Eph_R  = zeros(29,32,length(time_GPS));
        iono   = zeros(8,length(time_GPS));
    end

    if ~isempty(time_M)

        newtime_M = setdiff(time_GPS, time_M);       %MASTER missing epochs
        for i = 1 : length(newtime_M)

            pos = find(time_M == newtime_M(i) - 1);  %position before the "holes"

            time_M = [time_M(1:pos);  newtime_M(i);  time_M(pos+1:end)];
            pr1_M  = [pr1_M(:,1:pos)  zeros(32,1)    pr1_M(:,pos+1:end)];
            ph1_M  = [ph1_M(:,1:pos)  zeros(32,1)    ph1_M(:,pos+1:end)];
            snr_M  = [snr_M(:,1:pos)  zeros(32,1)    snr_M(:,pos+1:end)];
            pos_M  = [pos_M(:,1:pos)  zeros(3,1)     pos_M(:,pos+1:end)];

            Eph_M  = cat(3, Eph_M(:,:,1:pos), zeros(29,32,1), Eph_M(:,:,pos+1:end));
        end
    else
        time_M = time_GPS;
        pr1_M  = zeros(32,length(time_GPS));
        ph1_M  = zeros(32,length(time_GPS));
        snr_M  = zeros(32,length(time_GPS));
        pos_M  = zeros(3,length(time_GPS));
        Eph_M  = zeros(29,32,length(time_GPS));
    end

else
    loss_R = [];          %losses of signal (ROVER)
    loss_M = [];          %losses of signal (MASTER)
end

if (nargin == 3)
    waitbar(1,wait_dlg)
end

%if ephemerides coming from RTCM stream are not available, use rover ones
if (~Eph_M)
    Eph = Eph_R;
else
    Eph = Eph_M;
end