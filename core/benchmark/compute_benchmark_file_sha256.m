function value = compute_benchmark_file_sha256(path)
%COMPUTE_BENCHMARK_FILE_SHA256 Identify the exact original input file.

arguments
    path (1, 1) string
end
identifier = fopen(path, "rb");
if identifier < 0
    error("compute_benchmark_file_sha256:CannotRead", ...
        "Cannot read %s for hashing.", path);
end
cleanup = onCleanup(@() fclose(identifier));
bytes = fread(identifier, Inf, "*uint8");
digest = javaMethod("getInstance", ...
    "java.security.MessageDigest", "SHA-256");
digest.update(typecast(uint8(bytes(:)), "int8"));
raw = typecast(int8(digest.digest()), "uint8");
value = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
clear cleanup
end
