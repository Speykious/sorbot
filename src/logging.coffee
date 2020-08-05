{ relative, CROSSMARK } = require "./utils"
{ format }              = require "util"
fs                      = require "fs"

# Praise currying
# Note: the formatting syntax used is only useful for `blessed`
formatCrisis = (crisis) -> (crisisMsg) ->
  "{#ff6432-fg}[#{crisis} Crisis] {bold}#{CROSSMARK}{/} #{crisisMsg}"

logf = (path) -> (...args) -> fs.appendFileSync (relative path), format(...args) + "\n"
aslog = (name) -> "../logs/#{name}.log"

LOG =
  INIT:       aslog "init"       # For every kind of initialization
  MAIL:       aslog "mail"       # For mail related requests & errors
  DATABASE:   aslog "database"   # For database related requests & errors
  MESSAGES:   aslog "messages"   # For discord message requests & errors
  MODERATION: aslog "moderation" # For discord administration info
  WTF:        aslog "wtf"        # For whatever other weird shit happens

module.exports {
  formatCrisis
  logf
  LOG
}