{ CROSSMARK, SERVERS } = require "./constants"
{ format }             = require "util"

botCache = {}
logChannelCache = {}
lc = if process.env.LOCAL then "local_channels" else "channels"
logf = ((chid, args...) ->
  unless @bot then return console.log "Warning: trying to log without @bot being ready"
  unless logChannelCache[chid] then logChannelCache[chid] = await @bot.channels.fetch chid
  if args.length is 1 and args[0].embed
    return await logChannelCache[chid].send args[0]
  args = args.map (arg) -> if arg.length > 2000 then "#{arg[...1997]}..." else arg
  return await logChannelCache[chid].send(format args...)
).bind botCache

LOG =
  INIT:       SERVERS.logs[lc].init       # For every kind of initialization
  EMAIL:      SERVERS.logs[lc].email      # For email related requests & errors
  DATABASE:   SERVERS.logs[lc].database   # For database related requests & errors
  MESSAGES:   SERVERS.logs[lc].messages   # For discord message requests & errors
  MODERATION: SERVERS.logs[lc].moderation # For discord administration info
  WTF:        SERVERS.logs[lc].wtf        # For whatever other weird shit happens
  WARNING:    SERVERS.logs[lc].warning    # For now, only for UNIQUE CONSTRAINT WARNINGS

# Actually don't praise currying in coffeescript
formatCrisis = (crisis, crisisMsg) ->
  format "**[#{crisis} Crisis] #{CROSSMARK}**", crisisMsg

formatUser = (user) -> "**__#{user.tag}__** (#{user.id})"
formatGuild = (guild) -> "**#{guild.name}** (#{guild.id})"

#####################
## DISCORD HELPERS ##
#####################

# This is only used for admin commands
sendError = (channel, errorString, msDelay = 0) ->
  try
    errorMsg = await channel.send errorString
  catch err
    logf LOG.MESSAGES, (formatCrisis "Message", err)
  if errorMsg and msDelay then errorMsg.delete { timeout: msDelay }
  return Promise.resolve errorMsg

module.exports = {
  botCache
  logf
  LOG

  formatCrisis
  formatUser
  formatGuild
  sendError
}
