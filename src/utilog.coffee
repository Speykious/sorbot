path       = require "path"
fs         = require "fs"
{ format } = require "util"
YAML       = require "yaml"

relative = (s) -> path.resolve __dirname, "../", s
delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

sendError = (channel, errorString, msDelay = 5000) ->
  errorMsg = await channel
    .send errorString
    .catch (err) -> logf LOG.MESSAGES, (formatCrisis "Message", err)
  logf LOG.MESSAGES, "{bold}Sent error:{/} {#ff6432-fg}#{errorMsg.content}{/}"
  if errorMsg then errorMsg.delete { timeout: msDelay }
  return Promise.resolve errorMsg

forEach = (array, f) ->
  promises = []
  for element in array
    promises.push f element
  return Promise.all promises

readf  = (path)       -> fs.readFileSync  (relative path), "utf8"
writef = (path, data) -> fs.writeFileSync (relative path), data, "utf8"

CHECKMARK = "🗸"
CROSSMARK = "✗"

domains = YAML.parse readf "resources/domains.yaml"

# Actually don't praise currying in coffeescript
# Note: the formatting syntax used is only useful for `blessed`
formatCrisis = (crisis, crisisMsg) ->
  "{#ff6432-fg}[#{crisis} Crisis] {bold}#{CROSSMARK}{/} #{crisisMsg}"

formatUser = (user) ->
  "{bold}#{user.tag}{/} ({#8c9eff-fg}#{user.id}{/})"

logf = (path, ...args) -> fs.appendFileSync path, format(...args) + "\n"

aslog = if process.env.LOCAL
then (name) -> relative   "logs/#{name}.log"
else (name) -> "/var/logs/sorbot-3/#{name}.log"

LOG =
  INIT:       aslog "init"       # For every kind of initialization
  MAIL:       aslog "mail"       # For mail related requests & errors
  DATABASE:   aslog "database"   # For database related requests & errors
  MESSAGES:   aslog "messages"   # For discord message requests & errors
  MODERATION: aslog "moderation" # For discord administration info
  WTF:        aslog "wtf"        # For whatever other weird shit happens

testers = [
  "358960666238910465" # Speykious
  "419624396710477834" # Toast
  "194549333226422272" # Théo B.
]

isTester = (user) -> testers.includes user.id

module.exports = {
  relative
  delay
  sendError
  forEach
  readf
  writef
  CHECKMARK
  CROSSMARK

  domains

  formatCrisis
  formatUser
  logf
  LOG

  isTester
}
