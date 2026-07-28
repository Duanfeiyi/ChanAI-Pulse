function outputPath = write_v3_ctf_hdf5_example(outputPath)
%WRITE_V3_CTF_HDF5_EXAMPLE Write a deterministic MATLAB/Python test file.

arguments
    outputPath (1, 1) string
end

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

shape = [2, 1, 3, 2, 4];
values = reshape(0:(prod(shape) - 1), shape);
H = complex(values, values + 0.5);
axes = struct( ...
    "frequency_hz", (3.5e9 + (0:2) * 15e3).', ...
    "time_s", [0; 1e-3], ...
    "sample_index", (1:4).', ...
    "sample_position_m", [(0:3).', zeros(4, 1)]);
metadata = struct( ...
    "source", "matlab_python_roundtrip_example", ...
    "sample_semantics", "independent");
dataset = create_channel_dataset("ctf", struct("H", H), axes, metadata);
write_channel_dataset_hdf5(outputPath, dataset);
end
