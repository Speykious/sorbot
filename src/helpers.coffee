{ logf, LOG, formatCrisis } = require "./logging"
{ resolve }                 = require "path"
{ format }                  = require "util"
fs                          = require "fs"

relative = (s) -> resolve __dirname, "../", s
delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

forEach = (array, f) ->
  promises = []
  for element in array
    promises.push f element
  return Promise.all promises

readf  = (path)       -> fs.readFileSync  (relative path), "utf8"
writef = (path, data) -> fs.writeFileSync (relative path), data, "utf8"

#####################
## DISCORD HELPERS ##
#####################

sendError = (channel, errorString, msDelay = 5000) ->
  errorMsg = await channel
    .send errorString
    .catch (err) -> logf LOG.MESSAGES, (formatCrisis "Message", err)
  logf LOG.MESSAGES, "{bold}Sent error:{/} {#ff6432-fg}#{errorMsg.content}{/}"
  if errorMsg then errorMsg.delete { timeout: msDelay }
  return Promise.resolve errorMsg

module.exports = {
  relative
  delay
  forEach
  readf
  writef

  sendError
  isTester
}