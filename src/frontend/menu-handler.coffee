###

Embed menu data will be stored as `*.embed.yaml` files
in the path `src/frontend/pages/`.

EmbedMenu:
  @embed (MessageEmbed) - The actual formatted message on the page
  @reactons (Reactons) - The Reactons (Reaction + Button) for navigation

Reactons:
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


{ CROSSMARK, TESTERS }                  = require "../constants"
{ logf, LOG, formatCrisis, formatUser } = require "../logging"
{ relative, delay, readf, writef }      = require "../helpers"
YAML                                    = require "yaml"

mdir = "resources/pages/"

menuCache = {}

# Gets the menu object from .embed.yaml files
getMenu = (mpath) ->
  unless mpath of menuCache
  then menuCache[mpath] = YAML.parse readf mdir + mpath + ".embed.yaml"
  return menuCache[mpath]

# Sends the menu as a message.
# - menu: menu object typed according to the embed.schema.json yaml validation file.
# - user: Discord.User
# - msgid: discord snowflake representing the message id of the menu (optional).
sendMenu = (menu, user, msgid) ->
  if process.env.LOCAL
    if not (user.id in TESTERS)
      logf LOG.MESSAGES, "Tried to send a menu to non-tester user", formatUser user, "in LOCAL mode"
      return null
    
    logf LOG.MESSAGES, "Sending menu to tester", formatUser user
  
  try
    dmChannel = await user.createDM()
    
    msg = undefined
    if msgid # If we have a msgid, we delete the corresponding message
      msg = await dmChannel.messages.fetch msgid
      await msg.delete()
      msg = await msg.edit { embed: menu.embed }
    
    # We send a new one
    msg = await dmChannel.send { embed: menu.embed }
    
    # WE CAN'T REMOVE ANY REACTIONS IN DM CHANNELS
    await msg.react emoji for emoji of menu.reactons
    
    return msg
  catch err
    logf LOG.MESSAGES, (formatCrisis "Discord API", err)
    return undefined

module.exports = {
  getMenu
  sendMenu
  mdir
}
