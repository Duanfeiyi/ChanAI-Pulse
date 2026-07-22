function sha256 = compute_file_sha256(filePath)
%COMPUTE_FILE_SHA256 Return the standard SHA-256 digest of a file.
%   SHA256 = COMPUTE_FILE_SHA256(FILEPATH) reads FILEPATH as raw bytes and
%   returns a lowercase 64-character hexadecimal digest.

arguments
    filePath (1, 1) string
end

fid = fopen(filePath, 'rb');
if fid < 0
    error('compute_file_sha256:FileOpenFailed', ...
        'Unable to open file for hashing: %s', filePath);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
raw = fread(fid, Inf, '*uint8');

md = java.security.MessageDigest.getInstance('SHA-256');
digest = md.digest(raw);

% Java returns signed int8 values. Reinterpret the underlying bytes rather
% than casting them, because uint8(int8Value) saturates negative values.
digestBytes = typecast(digest, 'uint8');
sha256 = lower(string(reshape(dec2hex(digestBytes, 2).', 1, [])));
end
