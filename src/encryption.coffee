{ enc, AES } = require "crypto-js"

passphrase = String enc.Base64.parse process.env.PASSPHRASE

encryptid = (id) -> String AES.encrypt id, passphrase
decryptid = (encrypted) -> AES.decrypt encrypted, passphrase
                           .toString enc.Utf8

module.exports = {
  encryptid
  decryptid
}
