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

{ CROSSMARK } = require "../utils"
{ logf, LOG } = require "../logging"

# Sends the menu as a message.
# - menu: menu object typed according to the embed.schema.json yaml validation file.
# - user: Discord.User
# - msgid: discord snowflake representing the message id of the menu (optional).
sendMenu = (menu, user, msgid) ->
  try
    if msgid
      # If we have a msgid, we edit the corresponding message
      msg = await user.dmChannel.messages.fetch msgid
                  .edit { embed: menu.embed }
      return msg
    else
      # Else we send a new one
      msg = await user.dmChannel.send { embed: menu.embed }
      return msg
  catch err
    logf LOG.MESSAGES, (formatCrisis "Discord API", err)
    return undefined

module.exports = {
  sendMenu
}