function detection = detect_channel_data_type(metadata, dataStruct)
%DETECT_CHANNEL_DATA_TYPE Automatically identify channel data type from content.
%   detection = detect_channel_data_type(metadata, dataStruct) combines
%   metadata declarations and actual data fields to determine the true type.
%   It explicitly rejects false Complex-H claims.

disp('::');

detection = struct();
detection.detected_type = "Unknown";
detection.confidence = "Low";
detection.evidence = strings(0, 1);
detection.conflicts = strings(0, 1);
detection.requires_user_confirmation = true;

% Inspect actual content
has_H = isfield(dataStruct, 'H') && isnumeric(dataStruct.H);
has_re_im = isfield(dataStruct, 'realPart') && isfield(dataStruct, 'imagPart');
has_sage = isfield(dataStruct, 'alpha') && isfield(dataStruct, 'delay');
has_power = isfield(dataStruct, 'power') || isfield(dataStruct, 'pdp');

% Infer from actual fields
if has_H
    detection.detected_type = "Direct Complex H";
    detection.evidence(end+1, 1) = "Found numeric H matrix in content.";
    detection.confidence = "High";
elseif has_re_im
    detection.detected_type = "HDF5 Re/Im";
    detection.evidence(end+1, 1) = "Found separate real/imaginary parts.";
    detection.confidence = "High";
elseif has_sage
    detection.detected_type = "SAGE Parameters";
    detection.evidence(end+1, 1) = "Found SAGE path parameters (alpha, delay).";
    detection.confidence = "Medium";
elseif has_power
    detection.detected_type = "Legacy Power";
    detection.evidence(end+1, 1) = "Found legacy power/PDP fields without complex H.";
    detection.confidence = "Medium";
end

% Cross-check with metadata claims
if isfield(metadata, 'data_type') && strlength(string(metadata.data_type)) > 0
    declaredType = string(metadata.data_type);
    detection.evidence(end+1, 1) = "Metadata declares type as: " + declaredType;
    
    % Critical Validation: Catch fake Complex-H
    if strcmpi(declaredType, "Complex-H") && ~has_H && ~has_re_im && ~has_sage
        detection.conflicts(end+1, 1) = "Metadata claims Complex-H, but no valid complex data or Re/Im pairs found in file.";
        detection.requires_user_confirmation = true;
        detection.detected_type = "Conflict/Invalid";
    end
end

% Auto-approve if high confidence and no conflicts
if isempty(detection.conflicts) && detection.confidence == "High"
    detection.requires_user_confirmation = false;
end
end
