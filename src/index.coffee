require "dotenv-flow"
.config()

{ authorize }              = require "./mail/gindex"
gmain                      = require "./mail/gmain"
{ encryptid }              = require "./encryption"
{ Client }                 = require "discord.js"
{ relative, delay, sendError,
  LOG, formatCrisis, formatUser,
  readf, CROSSMARK, logf } = require "./utilog"
YAML                       = require "yaml"
User                       = require "./db/models/User"


bot = new Client {
  disableMentions: "everyone"
  partials: ['MESSAGE', 'CHANNEL', 'REACTION']
}
logf LOG.INIT, "{#ae6753-fg}Preparing the cup of coffee...{/}"

bot.on "ready", () ->
  # Using the tea kanji instead of the emoji
  # because it doesn't render well with blessed :(
  logf LOG.INIT, "{bold}{#ae6753-fg}Ready to sip. 茶{/}"
  ###
  bot.channels.cache.get "672498488646434841"
  .send "**GO BACK TO WORK, I NEED TO GET DONE** <@&672480366266810398>"
  ###

  try # Load client secrets from a local file.
    content = readf "../credentials.yaml"
    # Authorize a client with credentials, then call the Gmail API.
    authorize (YAML.parse content), gmain
  catch err
    logf LOG.INIT, (formatCrisis "Loading", "({underline}credentials.yaml{/underline}) #{err}")
  
  ### # was testing embeds
  templog "Printing some embed..."
  messageEmbed = await (bot.channels.cache.get "672514494903222311"
  .send {
    embed:
      title: "Re²-Testing in progress..."
      description: "Re²-Testing the addition of additional hidden data inside embeds 👀"
      footer:
        text: "Hello I'm a footer"
        icon_url: "https://gitlab.com/Speykious/sorbot-3/-/raw/master/resources/blackorbit-sorbonne-logo.png"
      hidden:
        some_string: "Hello I'm a string"
        something_else: yes
  })
  templogln green CHECKMARK + " Printed some embed"
  ###

bot.on "messageReactionRemove", (reaction, user) ->
  ###
  console.log """
              #{bold red "A new reaction was removed!"}
              Relevant information:
                - emoji   of the reaction: #{cyan   String reaction._emoji.name}
                - user    of the reaction: #{blue   String user.id}
                - message of the reaction: #{blue   String reaction.message.id}
                - source  of the reaction: #{yellow String reaction.message.channel.type}
              """
  ###

  # We don't care about messages that don't come from dms
  if reaction.message.channel.type != "dm" then return

  menuState = undefined
  try # Manages the fetching of menuState
    dbUser = await User.findByPk encryptid user.id
    if not dbUser then throw "User #{formatUser user} doesn't exist in our database"
    menuState = dbUser.menuState
  catch err
    # In this block we have to tell the user that they are not registered
    # in our database and that they should contact us or something
    logf LOG.DATABASE, (formatCrisis "Existential", err)

  if not menuState then return
  # Get the menu's message id
  menuMsgid = menuState.slice 0, 18
  if reaction.message.id != menuMsgid then return

  try # Get to the linked page and edit the message accordingly
    mpath = "../src/frontend/pages/" + menuState.slice 19
    pdir  = (split mpath, "/").pop().join("/") + "/"
    menu  = YAML.parse readf mpath + ".embed.yaml"
    reactonojis = Object.keys menu.reactons

    reactonoji = reactonojis.find (e) -> e == reaction._emoji.name
    if not reactonoji then return

    linked = YAML.parse readf mpath + menu.reactons[reactonoji] + ".embed.yaml"
    return sendMenu linked, user, reaction.message.id

  catch err
    logf LOG.MESSAGES, (formatCrisis "Menu Existential", err)

  ###
  We have to use the encrypted user.id
  to fetch the menu state from the user db
  ###

if process.env.LOCAL
then bot.login process.env.SLOCAL_TOKEN
else bot.login process.env.SORBOT_TOKEN
