function dataset = read_channel_dataset_hdf5(filePath)
%READ_CHANNEL_DATASET_HDF5 Read the v3 portable HDF5 exchange format.

arguments
    filePath (1, 1) string
end
if ~isfile(filePath)
    error("read_channel_dataset_hdf5:MissingFile", ...
        "HDF5 file does not exist: %s", filePath);
end

domain = lower(string(h5readatt(filePath, "/", "domain")));
metadata = jsondecode(char(h5readatt(filePath, "/", "metadata_json")));
axes = struct();
axisFields = ["frequency_hz", "time_s", "sample_index", ...
    "sample_position_m"];
for fieldName = axisFields
    basePath = "/axes/" + fieldName;
    if datasetExists(filePath, basePath + "_values")
        axes.(fieldName) = readRealFlat(filePath, basePath);
    end
end

if domain == "ctf"
    payload = struct("H", readComplexFlat(filePath, "/ctf/H"));
elseif domain == "cir"
    payload = struct( ...
        "coefficient", readComplexFlat(filePath, "/cir/coefficient"), ...
        "delay_s", readRealFlat(filePath, "/cir/delay_s"), ...
        "path_valid", logical(readRealFlat(filePath, "/cir/path_valid")));
    optionalPathFields = ["aoa_rad", "aod_rad", "doppler_hz"];
    for fieldName = optionalPathFields
        basePath = "/cir/" + fieldName;
        if datasetExists(filePath, basePath + "_values")
            payload.(fieldName) = readRealFlat(filePath, basePath);
        end
    end
else
    error("read_channel_dataset_hdf5:UnsupportedDomain", ...
        "Unsupported HDF5 domain: %s", domain);
end

dataset = create_channel_dataset(domain, payload, axes, metadata);
dataset.schema_version = string(h5readatt(filePath, "/", "schema_version"));
end

function value = readComplexFlat(filePath, basePath)
realPart = readRealFlat(filePath, basePath + "_real");
imagPart = readRealFlat(filePath, basePath + "_imag");
if ~isequal(size(realPart), size(imagPart))
    error("read_channel_dataset_hdf5:ComplexShapeMismatch", ...
        "Real and imaginary HDF5 datasets have different shapes.");
end
value = complex(realPart, imagPart);
end

function value = readRealFlat(filePath, basePath)
flatValue = h5read(filePath, basePath + "_values");
shape = double(h5read(filePath, basePath + "_shape"));
shape = shape(:).';
value = reshape(flatValue, shape);
end

function exists = datasetExists(filePath, datasetPath)
try
    h5info(filePath, datasetPath);
    exists = true;
catch
    exists = false;
end
end
