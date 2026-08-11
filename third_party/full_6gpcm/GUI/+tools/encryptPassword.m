function encryptedPassword = encryptPassword(password)
    md = java.security.MessageDigest.getInstance('SHA-256');
    md.update(uint8(password));
    hash = typecast(md.digest(), 'uint8');
    encryptedPassword = dec2hex(hash)';
    encryptedPassword = encryptedPassword(:)';
end