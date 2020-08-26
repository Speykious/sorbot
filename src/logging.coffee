{ appendFileSync } = require "fs"
{ format }         = require "util"
{ relative }       = require "./helpers"

logf = (path, args...) -> appendFileSync path, format(args...) + "\n"

aslog = if process.env.LOCAL
then (name) -> relative      "logs/#{name}.log"
else (name) -> "/var/logs/sorbot-3/#{name}.log"

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

module.exports = {
  logf
  LOG

  formatCrisis
  formatUser
}