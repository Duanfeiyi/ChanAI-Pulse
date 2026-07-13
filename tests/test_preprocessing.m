% ChanAI Pulse preprocessing test using temporary synthetic DPSD files.
clearvars;
clc;
repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));
tempRoot = tempname;
mkdir(tempRoot);
cleanupObj = onCleanup(@() rmdir(tempRoot, "s")); %#ok<NASGU>
for idx = [1, 2, 10, 11, 12, 13, 14, 15]
    dpsd = (1:4).' * idx * 1e-6; %#ok<NASGU>
    save(fullfile(tempRoot, sprintf("DPSD_1_%d.mat", idx)), "dpsd");
end
[sequence, fileMeta] = load_dpsd_sequence(tempRoot);
assert(isequal(size(sequence), [8, 4]), "Unexpected DPSD sequence size.");
assert(endsWith(fileMeta.files(1), "DPSD_1_1.mat") && endsWith(fileMeta.files(3), "DPSD_1_10.mat"), "Natural sorting did not preserve numeric order.");
dbm = power_to_dbm(sequence);
assert(all(isfinite(dbm), "all"), "Power conversion produced non-finite values.");
[inputs, targets, windowMeta] = build_sliding_windows(sequence, 3, 1);
assert(isequal(size(inputs), [5, 4, 3]), "Unexpected input window size.");
assert(isequal(size(targets), [5, 4]), "Unexpected target size.");
assert(windowMeta.target_indices(end) == 8, "Unexpected final target index.");
[normalized, params] = normalize_samples(inputs);
restored = denormalize_samples(normalized, params);
assert(max(abs(restored(:) - inputs(:))) < 1e-12, "Normalization round-trip changed data.");
split = create_train_test_split(inputs, targets, 0.4);
assert(size(split.train.inputs, 1) == 3 && size(split.test.inputs, 1) == 2, "Unexpected chronological split sizes.");
fprintf("PASS: preprocessing functions preserve synthetic DPSD data and chronological ordering.\n");
