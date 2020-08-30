require "dotenv-flow"
.config()

{ mdir, getMenu, sendMenu }             = require "./frontend/menu-handler"
{ getdbUser }                           = require "./db/dbhelpers"
{ GMailer }                             = require "./mail/gmailer"
{ encryptid }                           = require "./encryption"
{ User }                                = require "./db/initdb"
{ CROSSMARK }                           = require "./constants"
{ Client }                              = require "discord.js"
{ logf, LOG, formatCrisis, formatUser } = require "./logging"
{ relative, delay, sendError, readf }   = require "./helpers"
{ join }                                = require "path"
YAML                                    = require "yaml"



bot = new Client {
  disableMentions: "everyone"
  partials: ['MESSAGE', 'CHANNEL', 'REACTION']
}

gmailer = new GMailer ["readonly", "modify"], "credentials.yaml"

console.log "Starting"
logf LOG.INIT, "{#ae6753-fg}Preparing the cup of coffee...{/}"



bot.on "ready", () ->
  # Using the tea kanji instead of the emoji
  # because it doesn't render well with blessed :(
  logf LOG.INIT, "{bold}{#ae6753-fg}Ready to sip. 茶{/}"
  # bot.channels.cache.get "672498488646434841"
  # .send "**GO BACK TO WORK, I NEED TO GET DONE** <@&672480366266810398>"

  gmailer.authorize "token.yaml"
  
  console.log "Bot started successfully."



bot.on "guildMemberAdd", (member) ->
  logf LOG.MODERATION, "Adding user #{formatUser member.user}"

  welcome = "page1"
  menu = getMenu welcome
  menumsg = await sendMenu menu, member.user
  unless menumsg then return # no need to send an error msg

  # Add new entry in the database
  await User.create {
    id: member.user.id
    menuState: "#{menumsg.id}:#{welcome}"
  }

  logf LOG.DATABASE, "User #{formatUser member.user} added"



bot.on "guildMemberRemove", (member) ->
  logf LOG.MODERATION, "Removing user #{formatUser member.user}"
  dbUser = await getdbUser member.user
  unless dbUser then return
  # Yeeting dbUser out when someone leaves
  await dbUser.destroy()
  logf LOG.DATABASE, "User #{formatUser member.user} removed"



bot.on "messageReactionAdd", (reaction, user) ->
  ###
  Relevant information:
    - emoji   of the reaction: reaction._emoji.name
    - user    of the reaction: user.id
    - message of the reaction: reaction.message.id
    - source  of the reaction: reaction.message.channel.type
  ###

  # I don't care about myself lol
  if user.bot then return

  # We don't care about messages that don't come from dms
  if reaction.message.channel.type != "dm" then return

  dbUser = await getdbUser user
  unless dbUser then return

  menuState = dbUser.menuState

  # Get the menu's message id
  menuMsgid = menuState.slice 0, 18
  if reaction.message.id != menuMsgid then return

  try # Get to the linked page and edit the message accordingly
    mpath = menuState.slice 19
    console.log mpath
    pdir = mpath.split("/")
    console.log "pdir:", pdir
    pdir.pop()
    console.log "pdir (pop):", pdir
    pdir = pdir.join("/") + "/"
    if pdir is "/" then pdir = ""
    console.log "pdir (join):", pdir
    
    menu = getMenu mpath
    reactonojis = Object.keys menu.reactons

    reactonoji = reactonojis.find (e) -> e == reaction._emoji.name
    unless reactonoji then return
    
    console.log "menu reactons:", menu.reactons
    linked = join pdir + menu.reactons[reactonoji]
    console.log "linked:", linked
    lkmenu = getMenu linked
    menumsg = await sendMenu lkmenu, user, reaction.message.id
    unless menumsg then return

    dbUser.menuState = "#{menumsg.id}:#{linked}"
    await dbUser.save()
  catch err
    logf LOG.MESSAGES, (formatCrisis "Menu Existential", err)



bot.login process.env.SORBOT_TOKEN
