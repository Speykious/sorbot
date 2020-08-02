CryptoJS = require "crypto-js"

passphrase = String CryptoJS.enc.Base64.parse process.env.PASSPHRASE

encryptid = (id) -> String CryptoJS.AES.encrypt id, passphrase
decryptid = (crypted) -> CryptoJS.AES.decrypt crypted, passphrase
                        .toString CryptoJS.enc.Utf8

module.exports = {
  encryptid
  decryptid
}