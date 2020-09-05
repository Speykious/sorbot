###

Embed menu data will be stored as `*.embed.yaml` files
in the path `src/frontend/pages/`.

EmbedMenu:
  @embed (MessageEmbed) - The actual formatted message on the page
  @reactions (Reactions) - The reactions for navigation
  @thread (string) - The channel name where the menu should be if in a text channel

reactions:
  A key/value pair
  with the @emoji character of the reaction as the key
  and a @path to the page it links to as the value.

A menu event has to have those informations:
- the id of the discord message
- the id of the user
- the emoji of the reaction

The menu state contains:
- the id of the discord message where the embed page is displayed
- the path to the `.embed.yaml` file corresponding to the page

###


{ CROSSMARK, TESTERS }                      = require "../constants"
{ logf, LOG, formatCrisis, formatUser }     = require "../logging"
{ relative, delay, readf, writef, forEach } = require "../helpers"
YAML                                        = require "yaml"

mdir = "resources/pages/"

menuCache = {}

# Gets the menu object from .embed.yaml files
getMenu = (mpath) ->
  unless mpath of menuCache
  then menuCache[mpath] = YAML.parse readf mdir + mpath + ".embed.yaml"
  return menuCache[mpath]

# Sends the menu as a dm message.
# - menu: menu object typed according to the embed.schema.json yaml validation file.
# - user: Discord.User
# - msgid: discord snowflake representing the message id of the menu (optional).
sendDmMenu = (menu, user, msgid) ->
  if process.env.LOCAL
    unless (user.id in TESTERS)
      logf LOG.MESSAGES,
        "Tried to send a menu to non-tester user",
        (formatUser user), "in LOCAL mode {#ff6432-fg}(prevented){/}"
      return null
    
    logf LOG.MESSAGES, "Sending menu to tester", formatUser user
  
  try
    dmChannel = await user.createDM()
    
    if msgid # If we have a msgid, we delete the corresponding message
      msg = await dmChannel.messages.fetch msgid
      await msg.delete()
    
    # We send a new one
    msg = await dmChannel.send { embed: menu.embed }
    return msg
  catch err
    logf LOG.MESSAGES, (formatCrisis "Discord API", err)
    return undefined



# Sends the menu as a message on a text channel.
# - menu: menu object typed according to the embed.schema.json yaml validation file.
# - channel: Discord.TextChannel
# - msgid: discord snowflake representing the message id of the menu (optional).
sendMenu = (menu, channel, msgid) ->
  try
    msg = undefined
    if msgid # If we have a msgid, we edit the corresponding message
      msg = await channel.messages.fetch msgid
      await msg.edit { embed : menu.embed }
    else
      # We send a new one
      msg = await channel.send { embed: menu.embed }
    
    return msg
  catch err
    logf LOG.MESSAGES, (formatCrisis "Discord API", err)
    return undefined



module.exports = {
  getMenu
  sendDmMenu
  sendMenu
  mdir
}
