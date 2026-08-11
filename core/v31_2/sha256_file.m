function digest = sha256_file(filePath)
%SHA256_FILE Return lowercase SHA-256 for a local file.

arguments
    filePath (1, 1) string
end
if ~isfile(filePath)
    error("sha256_file:FileNotFound", "File does not exist: %s", filePath);
end
fid = fopen(filePath, "rb");
if fid < 0
    error("sha256_file:OpenFailed", "Cannot open file: %s", filePath);
end
cleanup = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, "*uint8");
engine = javaMethod("getInstance", "java.security.MessageDigest", "SHA-256");
engine.update(typecast(uint8(bytes(:)), "int8"));
raw = typecast(int8(engine.digest()), "uint8");
digest = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
end
