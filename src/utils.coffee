path = require "path"

relative = (s) -> path.resolve __dirname, s
delay = (ms) -> new Promise ((resolve) -> setTimeout resolve, ms)

sendError = (channel, errorString, msDelay = 5000) ->
  errorMsg = await channel
    .send errorString
    .catch () -> Promise.resolve()
  if errorMsg then errorMsg.delete { timeout: msDelay }
  return Promise.resolve errorMsg

module.exports = {
  relative,
  delay,
  sendError
}
