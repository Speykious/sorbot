path = require "path"
fs   = require "fs"

relative = (s) -> path.resolve __dirname, s
delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

sendError = (channel, errorString, msDelay = 5000) ->
  errorMsg = await channel
    .send errorString
    .catch () -> Promise.resolve()
  if errorMsg then errorMsg.delete { timeout: msDelay }
  return Promise.resolve errorMsg

forEach = (array, f) ->
  promises = []
  for element in array
    promises.push f element
  return Promise.all promises

readf  = (path)       -> fs.readFileSync  (relative path), "utf8"
writef = (path, data) -> fs.writeFileSync (relative path), data, "utf8"

# Erases the line it's currently on to then
# print s with(out) an automatic newline.
templog   = (s) -> process.stdout.write "\x1b[2K\r" + s
templogln = (s) -> templog s + "\n"

CHECKMARK = "✔"
CROSSMARK = "✗"

module.exports = {
  relative
  delay
  sendError
  forEach
  readf
  writef
  CHECKMARK
  CROSSMARK
  templog
  templogln
}
