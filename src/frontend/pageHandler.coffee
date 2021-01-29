###
Embed page data is stored as `*.embed.yaml` files
in the path `resources/pages/`.
###


{ CROSSMARK, TESTERS, FOOTER }              = require "../constants"
{ logf, LOG, formatCrisis, formatUser }     = require "../logging"
{ relative, delay, readf, writef, forEach } = require "../helpers"
YAML                                        = require "yaml"

# Sends the page as a dm message.
# - page: page object typed according to the embed.schema.json yaml validation file.
# - user: Discord.User
# - msgid: discord snowflake representing the message id of the page (optional).
sendDmPage = (page, user, msgid) ->
  if process.env.LOCAL
    unless user.id in TESTERS
      logf LOG.MESSAGES,
        "Tried to send a page to non-tester user",
        (formatUser user), "**in LOCAL mode** (prevented)"
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
    if /Cannot send messages to this user/.test err
      logf LOG.MESSAGES, (formatCrisis "Message sending",
        "Cannot send DM page to user #{formatUser user}, they probably deactivated their private messages")
    else
      logf LOG.MESSAGES, (formatCrisis "Discord API", err)
      
    return undefined


module.exports = {
  sendDmPage
}
