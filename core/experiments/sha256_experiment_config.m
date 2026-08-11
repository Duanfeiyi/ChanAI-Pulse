function digest = sha256_experiment_config(config)
%SHA256_EXPERIMENT_CONFIG Hash the canonical JSON representation of a config.

arguments
    config (1, 1) struct
end
bytes = unicode2native(char(jsonencode(config)), "UTF-8");
engine = javaMethod("getInstance", "java.security.MessageDigest", "SHA-256");
engine.update(typecast(uint8(bytes(:)), "int8"));
raw = typecast(int8(engine.digest()), "uint8");
digest = lower(string(reshape(dec2hex(raw, 2).', 1, [])));
end
