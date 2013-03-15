function goGPS_LS_SA_goD(time_rx_t0,time_rx_t1,pr1_t0,pr1_t1,pr2_t0, pr2_t1, ph1_t0,ph1_t1, ph2_t0,ph2_t1, snr_t0,snr_t1, Eph_t0, Eph_t1, SP3_time_t0,SP3_time_t1, SP3_coor_t0,SP3_coor_t1, SP3_clck_t0,SP3_clck_t1, iono, sbas, phase,time_step)
         
% SYNTAX:
%   goGPS_LS_SA_code_phase(time_rx, pr1, pr2, ph1, ph2, snr, Eph, SP3_time, SP3_coor, SP3_clck, iono, phase);
%
% INPUT:
%   time_rx  = GPS reception time
%   pr1      = code observations (L1 carrier)
%   pr2      = code observations (L2 carrier)
%   ph1      = phase observations (L1 carrier)
%   ph2      = phase observations (L2 carrier)
%   snr      = signal-to-noise ratio
%   Eph      = satellite ephemeris
%   SP3_time = precise ephemeris time
%   SP3_coor = precise ephemeris coordinates
%   SP3_clck = precise ephemeris clocks
%   iono     = ionosphere parameters
%   sbas     = (do not really work)
%   phase    = L1 carrier (phase=1), L2 carrier (phase=2)
%
% DESCRIPTION:
%   Computation of the receiver position (X,Y,Z).
%   Standalone code and phase positioning by least squares adjustment.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.3.0 beta
%
% Copyright (C) 2009-2012 Mirko Reguzzoni, Eugenio Realini
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

global sigmaq0 sigmaq0_N
global cutoff snr_threshold cond_num_threshold o1 o2 o3

global Xhat_t_t Cee conf_sat conf_cs pivot pivot_old
global azR elR distR
global PDOP HDOP VDOP

%covariance matrix initialization
cov_XR = [];

%topocentric coordinate initialization
azR   = zeros(32,1);
elR   = zeros(32,1);
distR = zeros(32,1);

%--------------------------------------------------------------------------------------------
% SELECTION SINGLE / DOUBLE FREQUENCY
%--------------------------------------------------------------------------------------------

%number of unknown phase ambiguities
if (length(phase) == 1)
    nN = 32;
else
    nN = 64;
end

%--------------------------------------------------------------------------------------------
% SATELLITE SELECTION
%--------------------------------------------------------------------------------------------

%if (length(phase) == 2)
%    sat_pr = find( (pr1 ~= 0) & (pr2 ~= 0) );
%    sat = find( (pr1 ~= 0) & (ph1 ~= 0) & ...
%        (pr2 ~= 0) & (ph2 ~= 0) );
%else

%% OLD VERSION OK 
   % if (phase == 1)
   %     sat_pr_t0 = find( (pr1_t0 ~= 0) & (pr2_t0 ~= 0)  );
   %     sat_t0 = find( (pr1_t0 ~= 0) & (ph1_t0 ~= 0)&(pr2_t0 ~= 0) );
   %     sat_pr_t1 = find( (pr1_t1 ~= 0) & (pr2_t1 ~= 0)  );
   %     sat_t1 = find( (pr1_t1 ~= 0) & (ph1_t1 ~= 0)&(pr2_t1 ~= 0) );
   % else
   %     sat_pr_t0 = find( (pr2_t0 ~= 0) );
   %     sat_t0 = find( (pr2_t0 ~= 0) & (ph2_t0 ~= 0) );
   %     sat_pr_t1 = find( (pr2_t1 ~= 0) );
   %     sat_t1 = find( (pr2_t1 ~= 0) & (ph2_t1 ~= 0) );
   % end
%% NEW VERSION
     if (phase == 1)
        sat_pr_t0 = find( (pr1_t0 ~= 0)   );
        sat_t0 = find( (pr1_t0 ~= 0) & (ph1_t0 ~= 0) );
        sat_pr_t1 = find( (pr1_t1 ~= 0)  );
        sat_t1 = find( (pr1_t1 ~= 0) & (ph1_t1 ~= 0) );
    else
        sat_pr_t0 = find( (pr2_t0 ~= 0) );
        sat_t0 = find( (pr2_t0 ~= 0) & (ph2_t0 ~= 0) );
        sat_pr_t1 = find( (pr2_t1 ~= 0) );
        sat_t1 = find( (pr2_t1 ~= 0) & (ph2_t1 ~= 0) );
    end
    
    
%end
sat_pr = intersect(sat_pr_t0,sat_pr_t1);
sat = intersect(sat_t0,sat_t1);
    sat_pr=intersect(sat_pr,sat);

% if length(sat_t0)<length(sat_t1)
%     sat_pr=intersect(sat_pr,sat);
% elseif length(sat_t0)>length(sat_t1)
%     sat=sat_pr;
% end



%zero vector useful in matrix definitions
Z_om_1 = zeros(o1-1,1);
sigma2_N = zeros(nN,1);

if (size(sat,1) >= 4)
    
    sat_pr_old = sat_pr;
    
    if (phase == 1)

        [XR_t0, dtR_t0, XS_t0, dtS_t0, XS_tx_t0, VS_tx_t0, time_tx_t0, err_tropo_t0, err_iono_t0, sat_pr, elR(sat_pr), azR(sat_pr), distR(sat_pr), cov_XR_t0, var_dtR_t, PDOP, HDOP, VDOP, cond_num] = init_positioning(time_rx_t0, pr1_t0(sat_pr), snr_t0(sat_pr), Eph_t0, SP3_time_t0, SP3_coor_t0, SP3_clck_t0, iono, sbas, [], [], [], sat_pr, cutoff, snr_threshold, 0, 0); %#ok<ASGLU>
        distR_t0(sat_pr)=distR(sat_pr);
        sat_pr_t0=sat_pr;
        sat_pr=sat_pr_old;
        [XR_t1, dtR_t1, XS_t1, dtS_t1, XS_tx_t1, VS_tx_t1, time_tx_t1, err_tropo_t1, err_iono_t1, sat_pr, elR(sat_pr), azR(sat_pr), distR(sat_pr), cov_XR_t1, var_dtR_t1, PDOP, HDOP, VDOP, cond_num] = init_positioning(time_rx_t1, pr1_t1(sat_pr), snr_t1(sat_pr), Eph_t0, SP3_time_t1, SP3_coor_t1, SP3_clck_t1, iono, sbas, [], [], [], sat_pr, cutoff, snr_threshold, 0, 0); %#ok<ASGLU>
        distR_t1(sat_pr)=distR(sat_pr);
        sat_pr_t1=sat_pr;

    else
        [XR, dtR, XS, dtS, XS_tx, VS_tx, time_tx, err_tropo, err_iono, sat_pr, elR(sat_pr), azR(sat_pr), distR(sat_pr), cov_XR, var_dtR, PDOP, HDOP, VDOP, cond_num] = init_positioning(time_rx, pr2(sat_pr), snr(sat_pr), Eph, SP3_time, SP3_coor, SP3_clck, iono, sbas, [], [], [], sat_pr, cutoff, snr_threshold, 0, 0); %#ok<ASGLU>
    end
  
        
    if length(sat_pr_t0)~=length(sat_pr_t1)
         sat_pr = intersect(sat_pr_t0,sat_pr_t1);    
        [XR_t0, dtR_t0, XS_t0, dtS_t0, XS_tx_t0, VS_tx_t0, time_tx_t0, err_tropo_t0, err_iono_t0, sat_pr, elR(sat_pr), azR(sat_pr), distR(sat_pr), cov_XR_t0, var_dtR_t, PDOP, HDOP, VDOP, cond_num] = init_positioning(time_rx_t0, pr1_t0(sat_pr), snr_t0(sat_pr), Eph_t0, SP3_time_t0, SP3_coor_t0, SP3_clck_t0, iono, sbas, [], [], [], sat_pr, cutoff, snr_threshold, 0, 0); %#ok<ASGLU>
        distR_t0(sat_pr)=distR(sat_pr);
        [XR_t1, dtR_t1, XS_t1, dtS_t1, XS_tx_t1, VS_tx_t1, time_tx_t1, err_tropo_t1, err_iono_t1, sat_pr, elR(sat_pr), azR(sat_pr), distR(sat_pr), cov_XR_t1, var_dtR_t1, PDOP, HDOP, VDOP, cond_num] = init_positioning(time_rx_t1, pr1_t1(sat_pr), snr_t1(sat_pr), Eph_t0, SP3_time_t1, SP3_coor_t1, SP3_clck_t1, iono, sbas, [], [], [], sat_pr, cutoff, snr_threshold, 0, 0); %#ok<ASGLU>
        distR_t1(sat_pr)=distR(sat_pr);

    end
    sat_removed = setdiff(sat_pr_old, sat_pr);
    sat(ismember(sat,sat_removed)) = [];     
    
    %--------------------------------------------------------------------------------------------
    % SATELLITE CONFIGURATION SAVING
    %--------------------------------------------------------------------------------------------
    
    %satellite configuration
    conf_sat = zeros(32,1);
    conf_sat(sat_pr,1) = -1;
    conf_sat(sat,1) = +1;
    
    %no cycle-slips when working with code only
    conf_cs = zeros(32,1);
    
    %previous pivot
    pivot_old = 0;
    
    %actual pivot
    [null_max_elR, i] = max(elR(sat)); %#ok<ASGLU>
    pivot = sat(i);
    
    %if less than 4 satellites are available after the cutoffs, or if the 
    % condition number in the least squares exceeds the threshold
    if (size(sat,1) < 4 | cond_num > cond_num_threshold)

        if (~isempty(Xhat_t_t))
            XR = Xhat_t_t([1,o1+1,o2+1]);
            pivot = 0;
        else
            return
        end
    end
else
    if (~isempty(Xhat_t_t))
        XR = Xhat_t_t([1,o1+1,o2+1]);
        pivot = 0;
    else
        return
    end
end

if isempty(cov_XR) %if it was not possible to compute the covariance matrix
    cov_XR = sigmaq0 * eye(3);
end
sigma2_XR = diag(cov_XR);

%do not use least squares ambiguity estimation
% NOTE: LS amb. estimation is automatically switched off if the number of
% satellites with phase available is not sufficient
%if (length(sat) < 4)
    
    %ambiguity initialization: initialized value
    %if the satellite is visible, 0 if the satellite is not visible
 %   N1 = zeros(32,1);
 %   N2 = zeros(32,1);
 %   sigma2_N1 = zeros(32,1);
 %   sigma2_N2 = zeros(32,1);
    
    %computation of the phase double differences in order to estimate N
 %   if ~isempty(sat)
 %      [N1(sat), sigma2_N1(sat)] = amb_estimate_observ_SA(pr1(sat), ph1(sat), 1);
 %       [N2(sat), sigma2_N2(sat)] = amb_estimate_observ_SA(pr2(sat), ph2(sat), 2);
 %   end

 %   if (length(phase) == 2)
 %       N = [N1; N2];
 %       sigma2_N = [sigma2_N1; sigma2_N2];
 %   else
 %       if (phase == 1)
 %           N = N1;
 %           sigma2_N = sigma2_N1;
 %       else
 %           N = N2;
 %           sigma2_N = sigma2_N2;
 %       end
 %   end

%use least squares ambiguity estimation
%else
    
    %ambiguity initialization: initialized value
    %if the satellite is visible, 0 if the satellite is not visible
 %   N1 = zeros(32,1);
 %5   N2 = zeros(32,1);

    %ROVER positioning improvement with code and phase double differences
    
    if ~isempty(sat)
        [XR, dtR, cov_XR, var_dtR,  PDOP, HDOP, VDOP] = LS_SA_code_goD(XR_t0,XR_t1, XS_t0,XS_t1,  ph1_t0(sat_pr),ph1_t1(sat_pr), snr_t0(sat_pr),snr_t1(sat_pr), elR(sat_pr), distR_t0(sat_pr), distR_t1(sat_pr), sat_pr, sat, dtS_t0,dtS_t1, err_tropo_t0,err_tropo_t1, err_iono_t0,err_iono_t1, 1); %#ok<ASGLU>
    end
    
    if isempty(cov_XR) %if it was not possible to compute the covariance matrix
        cov_XR = sigmaq0 * eye(3);
    end
    sigma2_XR = diag(cov_XR);
  
%     
%     if (length(phase) == 2)
%         N = [N1; N2];
%         sigma2_N(sat) = diag(cov_N1);
%         %sigma2_N(sat) = (sigmaq_cod1 / lambda1^2) * ones(length(sat),1);
%         sigma2_N(sat+nN) = diag(cov_N2);
%         %sigma2_N(sat+nN) = (sigmaq_cod2 / lambda2^2) * ones(length(sat),1);
%     else
%         if (phase == 1)
%             N = N1;
%             sigma2_N(sat) = diag(cov_N1);
%             %sigma2_N(sat) = (sigmaq_cod1 / lambda1^2) * ones(length(sat),1);
%         else
%             N = N2;
%             sigma2_N(sat) = diag(cov_N2);
%             %sigma2_N(sat) = (sigmaq_cod2 / lambda2^2) * ones(length(sat),1);
%         end
%     end
% %end

%initialization of the initial point with 6(positions and velocities) +
%32 or 64 (N combinations) variables
Xhat_t_t = [XR(1);sigma2_XR(1);  XR(2);sigma2_XR(2);  XR(3);sigma2_XR(3) ];

%--------------------------------------------------------------------------------------------
% INITIAL STATE COVARIANCE MATRIX
%--------------------------------------------------------------------------------------------

%initial state covariance matrix
Cee(:,:) = zeros(o3+nN);
Cee(1,1) = sigma2_XR(1);
Cee(o1+1,o1+1) = sigma2_XR(2);
Cee(o2+1,o2+1) = sigma2_XR(3);
Cee(2:o1,2:o1) = sigmaq0 * eye(o1-1);
Cee(o1+2:o2,o1+2:o2) = sigmaq0 * eye(o1-1);
Cee(o2+2:o3,o2+2:o3) = sigmaq0 * eye(o1-1);
Cee(o3+1:o3+nN,o3+1:o3+nN) = diag(sigma2_N);

