function manifest = hash_full_6gpcm_tree(engineRoot)
%HASH_FULL_6GPCM_TREE Build a read-only SHA-256 manifest for an engine tree.
%   The aggregate digest covers sorted lines:
%       file_sha256  size_bytes  relative/path

arguments
    engineRoot (1, 1) string
end

engineRoot = canonicalPath(engineRoot);
if strlength(strtrim(engineRoot)) == 0 || ~isfolder(engineRoot)
    error("hash_full_6gpcm_tree:MissingRoot", ...
        "The full 6GPCM engine root does not exist: %s", engineRoot);
end

items = dir(fullfile(engineRoot, "**", "*"));
items = items(~[items.isdir]);
if isempty(items)
    error("hash_full_6gpcm_tree:EmptyRoot", ...
        "The full 6GPCM engine root contains no files: %s", engineRoot);
end

fullPaths = strings(numel(items), 1);
relativePaths = strings(numel(items), 1);
rootPrefix = char(engineRoot);
if ~endsWith(rootPrefix, filesep)
    rootPrefix = [rootPrefix, filesep];
end
for index = 1:numel(items)
    fullPaths(index) = canonicalPath( ...
        fullfile(items(index).folder, items(index).name));
    fullPathChar = char(fullPaths(index));
    if ~startsWith(lower(fullPathChar), lower(rootPrefix))
        error("hash_full_6gpcm_tree:PathEscape", ...
            "File resolved outside the requested engine root: %s", fullPathChar);
    end
    relativePaths(index) = replace( ...
        string(fullPathChar(numel(rootPrefix) + 1:end)), "\", "/");
end

[relativePaths, order] = sort(relativePaths);
fullPaths = fullPaths(order);
items = items(order);

entries = repmat(struct( ...
    "path", "", "size_bytes", 0, "sha256", ""), numel(items), 1);
manifestLines = strings(numel(items), 1);
for index = 1:numel(items)
    fileHash = sha256File(fullPaths(index));
    entries(index).path = relativePaths(index);
    entries(index).size_bytes = double(items(index).bytes);
    entries(index).sha256 = fileHash;
    manifestLines(index) = fileHash + "  " + ...
        string(items(index).bytes) + "  " + relativePaths(index);
end

manifestText = strjoin(manifestLines, newline);
manifest = struct( ...
    "algorithm", "SHA-256", ...
    "file_count", numel(entries), ...
    "total_bytes", sum([entries.size_bytes]), ...
    "aggregate_sha256", sha256Bytes( ...
        unicode2native(char(manifestText), "UTF-8")), ...
    "entries", entries);
end

function value = canonicalPath(value)
fileObject = javaObject("java.io.File", char(string(value)));
value = string(fileObject.getCanonicalPath());
end

function fileHash = sha256File(filePath)
fileIdentifier = fopen(filePath, "rb");
if fileIdentifier < 0
    error("hash_full_6gpcm_tree:ReadFailed", ...
        "Could not read file for hashing: %s", filePath);
end
cleanup = onCleanup(@() fclose(fileIdentifier));
digest = javaMethod("getInstance", ...
    "java.security.MessageDigest", "SHA-256");
while ~feof(fileIdentifier)
    chunk = fread(fileIdentifier, 1024 * 1024, "*uint8");
    if ~isempty(chunk)
        digest.update(typecast(uint8(chunk(:)), "int8"));
    end
end
fileHash = digestToHex(digest.digest());
clear cleanup
end

function value = sha256Bytes(bytes)
digest = javaMethod("getInstance", ...
    "java.security.MessageDigest", "SHA-256");
digest.update(typecast(uint8(bytes(:)), "int8"));
value = digestToHex(digest.digest());
end

function value = digestToHex(digestBytes)
unsignedBytes = typecast(int8(digestBytes), "uint8");
value = lower(string(reshape(dec2hex(unsignedBytes, 2).', 1, [])));
end
