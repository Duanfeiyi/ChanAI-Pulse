function data = extract_raw_data(rawInput)
%EXTRACT_RAW_DATA Unwrap common measured-channel MATLAB containers.
% Mirrors the original App logic for DPSD, SAGE, CIR, and related fields.

data = rawInput;
while isstruct(data) || iscell(data)
    if isstruct(data)
        fields = fieldnames(data);
        if isempty(fields)
            error('Empty struct detected');
        end
        if isfield(data, 'DPSD_dB'), data = data.DPSD_dB; continue; end
        if isfield(data, 'DPSD_cut'), data = data.DPSD_cut; continue; end
        if isfield(data, 'sage'), tmp = localGetSageData(data.sage); data = tmp.cir; continue; end
        if isfield(data, 'cir'), data = data.cir; continue; end
        if isfield(data, 'CIRData'), data = data.CIRData; continue; end
        if isfield(data, 'IRuse'), data = data.IRuse; continue; end
        if isfield(data, 'input'), data = data.input; continue; end
        data = data.(fields{1});
    elseif iscell(data)
        if isempty(data)
            error('Empty cell array detected');
        end
        data = data{1};
    end
end

if isnumeric(data) || islogical(data)
    data = double(data);
else
    error('Data is non-numeric.');
end
end

function s = localGetSageData(rs)
if iscell(rs)
    s = rs{1};
else
    s = rs;
end
if length(s) > 1
    s = s(1);
end
end

