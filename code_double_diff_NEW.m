function [xR, Cxx, PDOP, HDOP, VDOP, comb_pr_app, comb_pr_obs, A] = code_double_diff ...
         (posR, pr_R, snr_R, posM, pr_M, snr_M, time_R, time_M, posS_R, dtS_R, posS_M, dtS_M, sat, pivot, iono)

% SYNTAX:
%   [xR, Cxx, PDOP, HDOP, VDOP, comb_pr_app, comb_pr_obs, A] = code_double_diff ...
%   (posR, pr_R, snr_R, posM, pr_M, snr_M, time_R, time_M, posS_R, dtS_R, posS_M, dtS_M, sat, pivot, iono);
%
% INPUT:
%   posR = ROVER position (X,Y,Z)
%   pr_R = ROVER-SATELLITE code pseudorange
%   snr_R = ROVER-SATELLITE signal-to-noise ratio
%   posM = MASTER position (X,Y,Z)
%   pr_M = MASTER-SATELLITE code pseudorange
%   snr_M = MASTER-SATELLITE signal-to-noise ratio
%   time_R = ROVER GPS time
%   time_M = MASTER GPS time
%   sat = visible satellite configuration
%   pivot = pivot satellite
%   iono = ionospheric parameters
%
% OUTPUT:
%   xR = estimated position (X,Y,Z)
%   Cxx = covariance matrix of estimation errors
%   PDOP = position dilution of precision
%   HDOP = horizontal dilution of precision
%   VDOP = vertical dilution of precision
%   comb_pr_app = crossed approximated pseudoranges
%                 (useful to verify that computations are done correctly)
%   comb_pr_obs = crossed observed pseudoranges
%                 (useful to verify that computations are done correctly)
%   A = design matrix
%
% DESCRIPTION:
%   Least squares solution using code double differences.
%   Epoch-by-epoch solution.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1.3 alpha
%
% Copyright (C) 2009-2011 Mirko Reguzzoni, Eugenio Realini
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

global v_light
global azR elR azM elM

%rover position coordinates X Y Z
X_R = posR(1);
Y_R = posR(2);
Z_R = posR(3);

%conversion from cartesian to geodetic coordinates
[phiR, lamR, hR] = cart2geod(X_R, Y_R, Z_R);

%master position coordinates X Y Z
X_M = posM(1);
Y_M = posM(2);
Z_M = posM(3);

%conversion from cartesian to geodetic coordinates
[phiM, lamM, hM] = cart2geod(X_M, Y_M, Z_M);

%radians to degrees
phiR = phiR * 180 / pi;
lamR = lamR * 180 / pi;
phiM = phiM * 180 / pi;
lamM = lamM * 180 / pi;

%number of visible satellites
nsat = size(sat,1);

%PIVOT satellite index
i = find(pivot == sat);

%PIVOT position
posP_R = posS_R(i,:);
posP_M = posS_M(i,:);

%PIVOT clock error
dtP_R = dtS_R(i);
dtP_M = dtS_M(i);

%computation of ROVER-PIVOT and MASTER-PIVOT approximated pseudoranges
prRP_app = sqrt(sum((posR - posP_R').^2));
prMP_app = sqrt(sum((posM - posP_M').^2));

%ROVER-PIVOT and MASTER-PIVOT observed code pseudoranges
prRP_obs = pr_R(i);
prMP_obs = pr_M(i);

%ROVER-PIVOT and MASTER-PIVOT tropospheric error computation
err_tropo_RP = err_tropo(elR(pivot), hR);
err_tropo_MP = err_tropo(elM(pivot), hM);

%ROVER-PIVOT and MASTER-PIVOT ionospheric error computation
err_iono_RP = err_iono(iono, phiR, lamR, azR(pivot), elR(pivot), time_R);
err_iono_MP = err_iono(iono, phiM, lamM, azM(pivot), elM(pivot), time_M);

A = [];
ts = [];
tr = [];
io = [];
comb_pr_app = [];
comb_pr_obs = [];

%computation of all linear combinations between PIVOT and other satellites
for i = 1 : nsat
    if (sat(i) ~= pivot)

        %computation of ROVER-SATELLITE and MASTER-SATELLITE approximated pseudoranges
        prRS_app = sqrt(sum((posR - posS_R(i,:)').^2));
        prMS_app = sqrt(sum((posM - posS_M(i,:)').^2));

        %observed code pseudoranges
        prRS_obs = pr_R(i);
        prMS_obs = pr_M(i);

        %design matrix computation
        A = [A; (((posR(1) - posS_R(i,1)) / prRS_app) - ((posR(1) - posP_R(1)) / prRP_app)) ...
                (((posR(2) - posS_R(i,2)) / prRS_app) - ((posR(2) - posP_R(2)) / prRP_app)) ...
                (((posR(3) - posS_R(i,3)) / prRS_app) - ((posR(3) - posP_R(3)) / prRP_app))];

        %computation of crossed approximated pseudoranges
        comb_pr_app = [comb_pr_app; (prRS_app - prMS_app) - (prRP_app - prMP_app)];

        %computation of crossed observed pseudoranges
        comb_pr_obs = [comb_pr_obs; (prRS_obs - prMS_obs) - (prRP_obs - prMP_obs)];
        
        %computation of crossed satellite clock errors
        ts = [ts; v_light*((dtS_R(i) - dtS_M(i)) - (dtP_R - dtP_M))];
        
        %computation of tropospheric errors
        err_tropo_RS = err_tropo(elR(sat(i)), hR);
        err_tropo_MS = err_tropo(elM(sat(i)), hM);
        
        %computation of crossed tropospheric errors
        tr = [tr; (err_tropo_RS - err_tropo_MS) - (err_tropo_RP - err_tropo_MP)];
        
        %computation of ionospheric errors
        err_iono_RS = err_iono(iono, phiR, lamR, azR(sat(i)), elR(sat(i)), time_R);
        err_iono_MS = err_iono(iono, phiM, lamM, azM(sat(i)), elM(sat(i)), time_M);
        
        %computation of crossed ionospheric errors
        io = [io; (err_iono_RS - err_iono_MS) - (err_iono_RP - err_iono_MP)];
    end
end

%vector of the b known term
b = comb_pr_app;

%correction of the b known term
b = b - ts + tr + io;

%observation vector
y0 = comb_pr_obs;

%number of observations
n = length(y0);

%number of unknown parameters
m = 3;

%observation covariance matrix
Q = cofactor_matrix(elR(sat), elM(sat), snr_R, snr_M, sat, pivot);

%least squares solution
x = ((A'*Q^-1*A)^-1)*A'*Q^-1*(y0-b);
xR = posR + x;

%estimation of the variance of the observation error
y_stim = A*x + b;
v_stim = y0 - y_stim;
sigma0q_stim = (v_stim' * Q^-1 * v_stim) / (n-m);

%covariance matrix of the estimation error
if (n > m)
    Cxx = sigma0q_stim * ((A'*Q^-1*A)^-1);
else
    Cxx = [];
end

%DOP computation
if (nargout > 2)
    cov_XYZ = (A'*A)^-1;
    cov_ENU = global2localCov(cov_XYZ, xR);
    
    PDOP = sqrt(cov_XYZ(1,1) + cov_XYZ(2,2) + cov_XYZ(3,3));
    HDOP = sqrt(cov_ENU(1,1) + cov_ENU(2,2));
    VDOP = sqrt(cov_ENU(3,3));
end