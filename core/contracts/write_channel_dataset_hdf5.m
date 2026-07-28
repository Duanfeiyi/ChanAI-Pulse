function write_channel_dataset_hdf5(filePath, dataset)
%WRITE_CHANNEL_DATASET_HDF5 Write portable MATLAB/Python HDF5 exchange file.
%   Complex arrays are stored as flat real/imag datasets plus an explicit
%   canonical shape. Python reconstructs them with reshape(order="F").

arguments
    filePath (1, 1) string
    dataset (1, 1) struct
end

report = validate_channel_dataset(dataset);
if ~report.is_valid
    error("write_channel_dataset_hdf5:InvalidDataset", ...
        "Dataset validation failed: %s", strjoin(report.errors, " | "));
end
if isfile(filePath)
    error("write_channel_dataset_hdf5:FileExists", ...
        "Refusing to overwrite existing file: %s", filePath);
end

domain = lower(string(dataset.domain));
if domain == "ctf"
    writeComplexFlat(filePath, "/ctf/H", dataset.ctf.H);
else
    writeComplexFlat(filePath, "/cir/coefficient", ...
        dataset.cir.coefficient);
    writeRealFlat(filePath, "/cir/delay_s", dataset.cir.delay_s, true);
    writeRealFlat(filePath, "/cir/path_valid", ...
        uint8(dataset.cir.path_valid), true);
    optionalPathFields = ["aoa_rad", "aod_rad", "doppler_hz"];
    for fieldName = optionalPathFields
        if isfield(dataset.cir, fieldName)
            writeRealFlat(filePath, "/cir/" + fieldName, ...
                dataset.cir.(fieldName), true);
        end
    end
end

axisFields = ["frequency_hz", "time_s", "sample_index", ...
    "sample_position_m"];
for fieldName = axisFields
    if isfield(dataset.axes, fieldName)
        writeRealFlat(filePath, "/axes/" + fieldName, ...
            dataset.axes.(fieldName), false);
    end
end

h5writeatt(filePath, "/", "schema_version", ...
    char(string(dataset.schema_version)));
h5writeatt(filePath, "/", "domain", char(domain));
h5writeatt(filePath, "/", "dimension_order_json", ...
    jsonencode(string(dataset.dimension_order)));
h5writeatt(filePath, "/", "units_json", jsonencode(dataset.units));
h5writeatt(filePath, "/", "metadata_json", jsonencode(dataset.metadata));
h5writeatt(filePath, "/", "complex_storage", "separate_real_imag");
h5writeatt(filePath, "/", "flatten_order", "MATLAB_column_major");
end

function writeComplexFlat(filePath, basePath, value)
writeRealFlat(filePath, basePath + "_real", real(value), true);
writeRealFlat(filePath, basePath + "_imag", imag(value), true);
end

function writeRealFlat(filePath, basePath, value, forceFiveDimensions)
flatValue = value(:);
if forceFiveDimensions
    shape = uint64(fiveDimensionalSize(value));
else
    shape = uint64(size(value));
end

h5create(filePath, basePath + "_values", size(flatValue), ...
    "Datatype", class(flatValue));
h5write(filePath, basePath + "_values", flatValue);
h5create(filePath, basePath + "_shape", size(shape), ...
    "Datatype", "uint64");
h5write(filePath, basePath + "_shape", shape);
end

function shape = fiveDimensionalSize(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
