function status = quadriga_check()
%QUADRIGA_CHECK Verify QuaDRiGa environment availability and compatibility.
%   status = quadriga_check() checks whether the official QuaDRiGa package
%   is installed, accessible, and compatible with the current MATLAB version.
%   If QuaDRiGa is found in common paths but not on the MATLAB path,
%   it will be added automatically.

status = struct();
status.is_available = false;
status.version = "";
status.matlab_version = version;
status.issues = {};
status.quadriga_path = '';

% Check if qd_layout class exists (core QuaDRiGa object)
try
    layout = qd_layout;
    status.is_available = true;
catch
    % QuaDRiGa not on path, try to find and add it
    quadriga_root = find_quadriga();
    if ~isempty(quadriga_root)
        addpath(genpath(quadriga_root));
        status.quadriga_path = quadriga_root;
        try
            layout = qd_layout;
            status.is_available = true;
        catch ME
            status.issues{end+1} = sprintf('QuaDRiGa found but failed to load: %s', ME.message);
        end
    else
        status.issues{end+1} = 'QuaDRiGa not found in common installation paths.';
    end
end

% Get version if available
if status.is_available
    try
        simpar = qd_simulation_parameters;
        if isprop(simpar, 'version')
            status.version = string(simpar.version);
        end
    catch
        % Version not available, not critical
    end
end

% Check MATLAB version compatibility (R2022b recommended)
matlab_ver = ver('MATLAB');
if ~isempty(matlab_ver)
    ver_parts = split(matlab_ver.Release, {'a', 'b'});
    if ~isempty(ver_parts)
        year_str = strtrim(ver_parts{1});
        if str2double(year_str) < 2022
            status.issues{end+1} = sprintf('MATLAB %s detected; R2022b+ recommended', ...
                matlab_ver.Release);
        end
    end
end

% Check required toolboxes
required_toolboxes = {'Deep Learning Toolbox', 'Signal Processing Toolbox'};
for idx = 1:numel(required_toolboxes)
    tbx = ver(required_toolboxes{idx});
    if isempty(tbx)
        status.issues{end+1} = sprintf('Missing toolbox: %s', required_toolboxes{idx});
    end
end

if status.is_available && isempty(status.issues)
    status.summary = 'QuaDRiGa environment OK';
else
    if status.is_available
        status.summary = sprintf('QuaDRiGa available with %d warning(s)', numel(status.issues));
    else
        status.summary = 'QuaDRiGa NOT available';
    end
end
end

function quadriga_root = find_quadriga()
%FIND_QUADRIGA Search for QuaDRiGa installation in common locations.
%   Returns the path to the quadriga_src directory, or empty if not found.

% Common installation paths to search
search_paths = { ...
    'D:\QuaDriGa_2023.12.13_v2.8.1-0\quadriga_src', ...
    'C:\QuaDriGa\quadriga_src', ...
    fullfile(getenv('USERPROFILE'), 'QuaDriGa', 'quadriga_src'), ...
    'D:\quadriga\quadriga_src', ...
    'C:\Program Files\QuaDRiGa\quadriga_src' ...
};

quadriga_root = '';
for idx = 1:numel(search_paths)
    if exist(fullfile(search_paths{idx}, '@qd_layout'), 'dir')
        quadriga_root = search_paths{idx};
        return;
    end
end

% Also search D:\ and C:\ root for any QuaDRiGa folder
if ispc
    drives = {'D:\', 'C:\'};
    for d = 1:numel(drives)
        dirs = dir(drives{d});
        for i = 1:numel(dirs)
            if dirs(i).isdir && contains(dirs(i).name, 'QuaDriGa', 'IgnoreCase', true)
                candidate = fullfile(drives{d}, dirs(i).name, 'quadriga_src');
                if exist(fullfile(candidate, '@qd_layout'), 'dir')
                    quadriga_root = candidate;
                    return;
                end
            end
        end
    end
end
end
