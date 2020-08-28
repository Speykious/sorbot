{ enc, AES } = require "crypto-js"

passphrase = if process.env.LOCAL
then process.env.LOCAL_PASSPHRASE
else process.env.PASSPHRASE

base64pass = String enc.Base64.parse passphrase

encryptid = (id) -> String AES.encrypt id, base64pass
decryptid = (encrypted) -> AES.decrypt encrypted, base64pass
                           .toString enc.Utf8

module.exports = {
  encryptid
  decryptid
}
