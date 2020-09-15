###

Embed page data will be stored as `*.embed.yaml` files
in the path `src/frontend/pages/`.

Embedpage:
  @embed (MessageEmbed) - The actual formatted message on the page
  @reactions (Reactions) - The reactions for navigation
  @thread (string) - The channel name where the page should be if in a text channel

reactions:
  A key/value pair
  with the @emoji character of the reaction as the key
  and a @path to the page it links to as the value.

A page event has to have those informations:
- the id of the discord message
- the id of the user
- the emoji of the reaction

The page state contains:
- the id of the discord message where the embed page is displayed
- the path to the `.embed.yaml` file corresponding to the page

###


{ CROSSMARK, TESTERS, FOOTER }              = require "../constants"
{ logf, LOG, formatCrisis, formatUser }     = require "../logging"
{ relative, delay, readf, writef, forEach } = require "../helpers"
YAML                                        = require "yaml"

mdir = "resources/pages/"

pageCache = {}

clearPageCache = -> pageCache = {}

# Gets the page object from .embed.yaml files
getPage = (mpath) ->
  unless mpath of pageCache
    pageCache[mpath] = YAML.parse readf mdir + mpath + ".embed.yaml"
    pageCache[mpath].embed.footer = FOOTER
  return pageCache[mpath]

# Sends the page as a dm message.
# - page: page object typed according to the embed.schema.json yaml validation file.
# - user: Discord.User
# - msgid: discord snowflake representing the message id of the page (optional).
sendDmPage = (page, user, msgid) ->
  if process.env.LOCAL
    unless (user.id in TESTERS)
      logf LOG.MESSAGES,
        "Tried to send a page to non-tester user",
        (formatUser user), "in LOCAL mode {#ff6432-fg}(prevented){/}"
      return null
    
    logf LOG.MESSAGES, "Sending page to tester", formatUser user
  
  try
    dmChannel = await user.createDM()
    
    if msgid # If we have a msgid, we delete the corresponding message
      msg = await dmChannel.messages.fetch msgid
      await msg.delete()
    
    # We send a new one
    msg = await dmChannel.send { embed: page.embed }
    return msg
  catch err
    logf LOG.MESSAGES, (formatCrisis "Discord API", err)
    return undefined


module.exports = {
  mdir
  clearPageCache
  getPage
  sendDmPage
}
