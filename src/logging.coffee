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
  INIT: aslog "init"
  MAIL: aslog "mail"