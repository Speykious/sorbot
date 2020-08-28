{ createHash, createCipheriv, createDecipheriv } = require "crypto"

iv = Buffer.allocUnsafe(16)
temphash = createHash "sha256"
           .update process.env.IV
           .digest()
temphash.copy iv

key = createHash "sha256"
      .update process.env.PASSPHRASE
      .digest()

encoding = "base64"



encryptid = (id) ->
  cipher = createCipheriv "aes256", key, iv
  di  = cipher.update id, "binary", encoding
  di += cipher.final encoding
  return di

decryptid = (di) ->
  decipher = createDecipheriv "aes256", key, iv
  id  = decipher.update di, encoding, "binary"
  id += decipher.final "binary"
  return id



module.exports = {
  encryptid
  decryptid
}
