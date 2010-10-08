function update_settings(settings_dir_path, field, value)

% SYNTAX:
%   update_settings(settings_dir_path, field, value);
%
% INPUT:
%   settings_dir_path = path to settings folder
%   field = name of the field to be added
%   value = default value for the field (-1 to remove the field)
%
% DESCRIPTION:
%   Utility to update goGPS settings file.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1.2 alpha
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

%directory containing settings files
settings_dir = dir(settings_dir_path);

%check the number of files contained in the directory
nmax = size(settings_dir,1);

j = 0;
for i = 1 : nmax

    %read the name of the i-th file
    got = getfield(settings_dir,{i,1},'name');

    %get the number of characters in the filename
    fn_length = size(got,2);

    %check that the filename has the ".hdr" extension
    if (fn_length >= 4 & strcmp(got(fn_length - 3 : fn_length), '.mat'))
        
        j = j+1;
        %load the settings file
        load([settings_dir_path '/' got]);
        %check if settings were loaded
        try
            if isstruct(state)
                if (value ~= -1)
                    %add the new field to 'state' struct
                    state.(field) = value;
                else
                    %remove the specified field from the 'state' struct
                    state = rmfield(state,field);
                end
            end
        catch
        end
        %save the new state in settings file
        save([settings_dir_path '/' got], 'state');
    end
end

if (j == 0)
    error(['No settings file found in folder ' settings_dir_path '.']);
else
    fprintf('%d settings files processed.\n', j);
end