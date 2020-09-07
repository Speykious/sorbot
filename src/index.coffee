loading = require "./loading"
loading.step "Loading dotenv-flow...", 0
loading.startInterval()

require "dotenv-flow"
.config()

loading.step "Loading nodejs dependencies..."
{ join }                                = require "path"
YAML                                    = require "yaml"

loading.step "Loading discord.js..."
{ Client }                              = require "discord.js"

loading.step "Loading generic utils..."
{ relative, delay, sendError, readf }   = require "./helpers"
{ logf, LOG, formatCrisis, formatUser } = require "./logging"
{ CROSSMARK, SERVERS, GUILDS, TESTERS } = require "./constants"
{ encryptid }                           = require "./encryption"

loading.step "Loading gmailer..."
{ GMailer }                             = require "./mail/gmailer"

loading.step "Loading frontend functions..."
syscall                                 = require "./frontend/syscall"
{ mdir, getMenu, sendMenu }             = require "./frontend/menu-handler"

loading.step "Loading dbhelpers..."
{ getdbUser }                           = require "./db/dbhelpers"
loading.step "Initializing database..."
{ User }                                = require "./db/initdb"


loading.step "Instantiating Discord client..."
bot = new Client {
  disableMentions: "everyone"
  partials: ['MESSAGE', 'CHANNEL', 'REACTION']
  restTimeOffset: 100
}

loading.step "Instantiating new GMailer..."
gmailer = new GMailer ["readonly", "modify", "compose", "send"], "credentials.yaml"

loading.step "Preparing the cup of coffee..."
logf LOG.INIT, "{#ae6753-fg}Preparing the cup of coffee...{/}"

bot.on "ready", () ->
  await bot.user.setPresence {
    activity:
      type: "PLAYING"
      name: "with your data 👀"
      url: "https://gitlab.com/Speykious/sorbot-3"
  }
  
  # Using the tea kanji instead of the emoji
  # because it doesn't render well with blessed :(
  logf LOG.INIT, "{bold}{#ae6753-fg}Ready to sip. 茶{/}"
  # bot.channels.cache.get "672498488646434841"
  # .send "**GO BACK TO WORK, I NEED TO GET DONE** <@&672480366266810398>"
  

  loading.step "Authorizing the gmailer..."
  await gmailer.authorize "token.yaml"
  
  loading.step "Fetching main guild..."
  GUILDS.MAIN = await bot.guilds.fetch SERVERS.main.id
  
  loading.step "Bot started successfully."
  setTimeout (-> console.log ""), 1000


bot.on "guildMemberAdd", (member) ->
  # For now we only care about the main server.
  # Federated server autoverification coming soon™
  if member.guild.id isnt GUILDS.MAIN.id then return
  
  logf LOG.MODERATION, "Adding user #{formatUser member.user}"
  await member.roles.add SERVERS.main.roles.non_verifie
  
  welcome = "welcomedm"
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



# The messageReactionAdd event is only used when handling the menus
bot.on "messageReactionAdd", (reaction, user) ->
  # I don't care about myself lol
  if user.bot then return
  
  # We don't care about messages that don't come from dms
  if reaction.message.channel.type isnt "dm" then return
  
  dbUser = await getdbUser user
  unless dbUser then return
  menuState = dbUser.menuState
  
  # Get the menu's message id
  menuMsgid = menuState.slice 0, 18
  if reaction.message.id isnt menuMsgid then return
  
  try # Get to the linked page and edit the message accordingly
    mpath = menuState.slice 19
    
    pdir = mpath.split("/")
    pdir.pop()
    pdir = pdir.join("/") + "/"
    if pdir is "/" then pdir = ""
    
    menu = getMenu mpath
    
    reactiontojis = Object.keys menu.reactions
    reactiontoji = reactiontojis.find (e) -> e == reaction._emoji.name
    unless reactiontoji then return
    
    linked = join pdir + menu.reactions[reactiontoji]
    lkmenu = getMenu linked
    menumsg = await sendMenu lkmenu, user, reaction.message.id
    unless menumsg then return
    
    dbUser.menuState = "#{menumsg.id}:#{linked}"
    await dbUser.save()
  catch err
    logf LOG.MESSAGES, (formatCrisis "Menu Existential", err)



bot.on "message", (msg) ->
  # I don't care about myself lol
  if msg.author.bot then return
  
  # We STILL don't care about messages that don't come from dms
  # Although we will care a bit later when introducing admin commands
  if msg.channel.type isnt "dm"
    unless msg.author.id in TESTERS then return
    
    syscall GUILDS.MAIN, msg
    return
  
  dbUser = await getdbUser msg.author
  unless dbUser then return
  
  # Remember from SorBOT 2:
  # - If no email, we try to register the email
  # - If email and code, we verify the code
  # - If email but no code, the user is verified
  if dbUser.email is null # Email verification stuff
    await gmailer.verifyEmail dbUser, msg.author, msg.content
  else if dbUser.code # Code verification stuff
    if msg.content == dbUser.code
      dbUser.code = null
      member = await GUILDS.MAIN.members.fetch msg.author.id
      
      # Hmmmmmmm what do we do here
    else
      sendError msg.channel, "**Erreur :** Le code n'est pas le bon. Réessayez."
  else
    # More stuff is gonna go here probably,
    # like user commands to request your
    # decrypted data from the database
    msg.author.send "Vous êtes vérifié(e), vous n'avez plus rien à craindre. *(more options coming soon™)*"


bot.login process.env.SORBOT_TOKEN
