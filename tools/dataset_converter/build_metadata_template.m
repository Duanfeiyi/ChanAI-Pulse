function metadata = build_metadata_template(varargin)
%BUILD_METADATA_TEMPLATE Create a ChanAIs metadata template.
%   metadata = build_metadata_template("dataset_id", "demo") returns a
%   struct with required ChanAIs Dataset fields. Name-value pairs override
%   the default placeholders.

metadata = struct();
metadata.schema_version = "ChanAIs-Dataset-v1.0-draft";
metadata.dataset_version = "1.0.0";
metadata.dataset_id = "chanais_dataset_id";
metadata.scenario = "unspecified";
metadata.environment = "unspecified";
metadata.frequency_band = "unspecified";
metadata.carrier_frequency = [];
metadata.bandwidth = [];
metadata.antenna_configuration = "unspecified";
metadata.polarization = "unspecified";
metadata.mobility = "unspecified";
metadata.trajectory = "unspecified";
metadata.los_condition = "unknown";
metadata.sampling_interval = [];
metadata.time_window = "unspecified";
metadata.data_source = "unspecified";
metadata.data_type = "SAGE";
metadata.license = "unspecified";
metadata.visibility = "internal_only";
metadata.units = struct("delay", "s", "frequency", "Hz", "angle", "degree", "power", "linear_or_dB");
metadata.notes = "";

if mod(numel(varargin), 2) ~= 0
    error("build_metadata_template:InvalidInput", "Name-value inputs must appear in pairs.");
end

for idx = 1:2:numel(varargin)
    name = string(varargin{idx});
    value = varargin{idx + 1};
    metadata.(matlab.lang.makeValidName(name)) = value;
end
end

