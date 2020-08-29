{ appendFileSync } = require "fs"
{ formatWithOptions }         = require "util"
{ relative }       = require "./helpers"
{ CROSSMARK }      = require "./constants"

logf = (path, args...) -> appendFileSync path,
  (formatWithOptions { colors: true }, "", args...) + "\n"

aslog = if process.env.LOCAL
then (name) -> relative "logs/#{name}.log"
else (name) -> "/var/log/sorbot-3/#{name}.log"

LOG =
  INIT:       aslog "init"       # For every kind of initialization
  MAIL:       aslog "mail"       # For mail related requests & errors
  DATABASE:   aslog "database"   # For database related requests & errors
  MESSAGES:   aslog "messages"   # For discord message requests & errors
  MODERATION: aslog "moderation" # For discord administration info
  WTF:        aslog "wtf"        # For whatever other weird shit happens

# Actually don't praise currying in coffeescript
# Note: the formatting syntax used is only useful for `blessed`
formatCrisis = (crisis, crisisMsg) ->
  "{#ff6432-fg}[#{crisis} Crisis] {bold}#{CROSSMARK}{/} #{crisisMsg}"

formatUser = (user) ->
  "{bold}#{user.tag}{/} ({#8c9eff-fg}#{user.id}{/})"

# Truncates a string. Make maxc > 3 to be sure it works.
truncateStr = (s, maxc = 50) ->
  if s.length <= maxc then s
  else "#{s.slice 0, maxc - 3}..."

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
  logf
  LOG

  formatCrisis
  formatUser
  truncateStr
  sendError
}
