function nmeastring = NMEA_RMC_gen(pos_R, date)

% SYNTAX:
%   nmeastring = NMEA_RMC_gen(pos_R, date);
%
% INPUT:
%   pos_R = estimated ROVER position (X,Y,Z)
%   date = date (yy mm dd hh mm ss)
%
% OUTPUT:
%   nmeastring = $GPRMC sentence (NMEA)
%
% DESCRIPTION:
%   Returns a $GPRMC sentence in NMEA 0183 format.

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

%approximate coordinates X Y Z
X = pos_R(1);
Y = pos_R(2);
Z = pos_R(3);

%conversion from cartesian to geodetic coordinates
[phi, lam] = cart2geod(X, Y, Z);

%conversion from radians to degrees
lam = abs(lam*180/pi);
phi = abs(phi*180/pi);

%-----------------------------------------------------------------------------------------------
% FORMAT COORDINATES ACCORDING TO NMEA STANDARD
%-----------------------------------------------------------------------------------------------

%longitude
lam_deg = floor(lam);
lam_min = (lam - lam_deg) * 60;
lam_nmea = lam_deg * 100 + lam_min;

if (length(num2str(lam_deg)) == 1 )
    [lam_nmea] = sprintf('00%s', num2str(lam_nmea, '%.8f'));
elseif (length(num2str(lam_deg)) == 2 )
    [lam_nmea] = sprintf('0%s', num2str(lam_nmea, '%.8f'));
else
    lam_nmea = num2str(lam_nmea,'%.8f');
end

%latitude
phi_deg = floor(phi);
phi_min = (phi - phi_deg) * 60;
phi_nmea = phi_deg * 100 + phi_min;

if (length(num2str(phi_deg)) == 1 )
    [phi_nmea] = sprintf('0%s',num2str(phi_nmea,'%.8f'));
else
    phi_nmea = num2str(phi_nmea,'%.8f');
end

%emisphere definition
if (lam >= 0)
    emi_EW = 'E';
else
    emi_EW = 'W';
end

if (phi >= 0)
    emi_NS = 'N';
else
    emi_NS = 'S';
end

%-----------------------------------------------------------------------------------------------
% OTHER NMEA PARAMETERS
%-----------------------------------------------------------------------------------------------

status = 'A';  %V = navigation receiver warning, A = Valid
speed = ''; %speed over ground (knots), to be changed

%-----------------------------------------------------------------------------------------------
% FORMAT DATA
%-----------------------------------------------------------------------------------------------

hour = num2str(date(1,4));
minute = num2str(date(1,5));
second = num2str(floor(date(1,6)));

[null, nchar] = size(hour); %#ok<ASGLU>
if (nchar == 1)
    [hour] = sprintf('0%s',hour);
end

[null, nchar] = size(minute); %#ok<ASGLU>
if (nchar == 1)
    [minute] = sprintf('0%s',minute);
end

[null, nchar] = size(second); %#ok<ASGLU>
if (nchar == 1)
    [second] = sprintf('0%s',second);
end

decsec = '.00';

day = num2str(date(1,3));
month = num2str(date(1,2));
year = num2str(date(1,1));

[null, nchar] = size(day); %#ok<ASGLU>
if (nchar == 1)
    [day] = sprintf('0%s',day);
end

[null, nchar] = size(month); %#ok<ASGLU>
if (nchar == 1)
    [month] = sprintf('0%s',month);
end

[null, nchar] = size(year); %#ok<ASGLU>
if (nchar == 1)
    [year] = sprintf('0%s',year);
end

%-----------------------------------------------------------------------------------------------
% COMPOSITION OF THE NMEA SENTENCE
%-----------------------------------------------------------------------------------------------

nmeastring = sprintf('$GPRMC,%s%s%s%s,%c,%s,%c,%s,%c,%s,,%s%s%s,,,,',hour,minute,second,decsec,status,phi_nmea,emi_NS,lam_nmea,emi_EW,speed,day,month,year);

%-----------------------------------------------------------------------------------------------
% CHECKSUM COMPUTATION
%-----------------------------------------------------------------------------------------------

checksum = NMEA_checksum(nmeastring);
nmeastring = [nmeastring '*' checksum];