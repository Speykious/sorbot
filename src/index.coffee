loading = require "./loading"
loading.step "Loading dotenv-flow...", 0
loading.startDisplaying()

require "dotenv-flow"
.config()

loading.step "Loading nodejs dependencies..."
{ join }                      = require "path"
YAML                          = require "yaml"
{ UniqueConstraintError }     = require "sequelize"

loading.step "Loading discord.js..."
{ Client }                    = require "discord.js"

loading.step "Loading generic utils..."
{ relative, delay, readf
  removeElement }             = require "./helpers"
{ logf, formatCrisis, formatGuild
  LOG, formatUser, botCache } = require "./logging"
{ CROSSMARK, SERVERS, BYEBYES,
  GUILDS, TESTERS, FOOTER }   = require "./constants"
{ encryptid, decryptid }      = require "./encryption"
{ updateMemberRoles }         = require "./roles"
touchMember                   = require "./touchMember"

loading.step "Loading gmailer and email crisis handler..."
GMailer                       = require "./mail/gmailer"
EmailCrisisHandler            = require "./mail/crisisHandler"
{ handleVerification }        = require "./mail/verificationHandler"

loading.step "Loading frontend functions..."
syscall                       = require "./frontend/syscall"
RTFM                          = require "./frontend/RTFM"

loading.step "Loading dbhelpers..."
{ getdbUser, getdbGuild }     = require "./db/dbhelpers"
loading.step "Initializing database..."
{ User, FederatedMetadata }   = require "./db/initdb"


loading.step "Instantiating Discord client..."
bot = new Client {
  disableMentions: "everyone"
  partials: ["MESSAGE", "CHANNEL", "REACTION", "GUILD_MEMBER"]
  restTimeOffset: 100
}

loading.step "Instantiating new GMailer and EmailCrisisHandler..."
gmailer = new GMailer ["readonly", "modify", "compose", "send"], "credentials.yaml", loading

# - slowT          {number}  - period for the slow read mode, in seconds
# - fastT          {number}  - period for the fast read mode, in seconds
# - maxThreads     {number}  - Maximum number of threads globally
# - maxThreadsSlow {number}  - Maximum number of threads only for slow mode
# - maxThreadsFast {number}  - Maximum number of threads only for fast mode
# - guild          {Guild}   - The main discord guild to handle the crisis with
# - gmailer        {GMailer} - The gmailer to read the email threads with
# - embedUEC       {Embed}   - The embed error report for Unread Existential Crisis
# - embedUSC       {Embed}   - The embed error report for Unread Sorbonne Crisis
emailCH = new EmailCrisisHandler {
  bot
  gmailer

  # About those embeds, I'm probably gonna isolate
  # them in a yaml file somewhere in resources/...

  embedUEC: (th) ->
    embed:
      title: "Existential Crisis : Adresse Introuvable"
      description:
        """
        L'adresse que vous avez renseignée, `#{th[0].to}`, semble ne pas exister.
        Nous vous invitons à réessayer avec une autre adresse mail universitaire.
        """
      fields: [
        {
          name: "Headers du mail envoyé",
          value: "```yaml\n#{YAML.stringify th[0]}```"
        },
        {
          name: "Headers de la notification de fail"
          value: "```yaml\n#{YAML.stringify th[1]}```"
        }
      ]
      color: 0xff6432
      footer: FOOTER

  embedUSC: (th) ->
    embed:
      title: "Sorbonne Crisis : Retour à l'envoyeur"
      description:
        """
        Pour une raison ou une autre, nous n'avons pas réussi à envoyer un mail à l'adresse `#{th[0].to}`.
        **Nous vous invitons donc à envoyer un mail depuis votre adresse universitaire à l'adresse `bot.sorbonne.jussieu@gmail.com`.**
        Attention : __Le sujet du mail doit obligatoirement être votre tag discord__, à savoir de la forme `pseudo#1234`, sinon il nous sera impossible de vous vérifier.
        Vous êtes libre d'écrire ce que vous voulez dans le corps du mail.
        """
      fields: [
        {
          name: "Headers du mail envoyé",
          value: "```yaml\n#{YAML.stringify th[0]}```"
        },
        {
          name: "Headers de la notification de fail"
          value: "```yaml\n#{YAML.stringify th[1]}```"
        }
      ]
      color: 0xa3334c
      footer: FOOTER
}

loading.step "Preparing the cup of coffee..."

bot.on "ready", ->
  botCache.bot = bot
  await bot.user.setPresence {
    activity:
      type: "PLAYING"
      name: if process.env.LOCAL then "Coucou humain 👀" else "with your data 👀"
      url: "https://gitlab.com/Speykious/sorbot"
  }
  
  logf LOG.INIT, {
    embed:
      title: "Ready to sip. 茶 ☕"
      description: "Let's play with even more dynamically-typed ***DATA*** <a:eyeshake:691797273147080714>"
      color: 0x34d9ff
      footer: FOOTER
  }

  loading.step "Authorizing the gmailer..."
  await gmailer.authorize "token.yaml"
  
  loading.step "Bot started successfully."
  setTimeout (-> emailCH.activate()), 100

bot.on "guildCreate", (guild) ->
  try
    dbGuild = await FederatedMetadata.create { id: guild.id }
    logf LOG.DATABASE, "New guild #{formatGuild guild} has been added to the database"
  catch e
    unless e instanceof UniqueConstraintError
      logf LOG.WTF, "**WTF ?!** Unexpected error when creating guild! Please check the console log."
      console.log "\x1b[1mUNEXPECTED ERROR WHEN CREATING GUILD\x1b[0m"
      console.log e
      return
    logf LOG.DATABASE, "Guild #{formatGuild guild} already existed in the database"
  
  RTFM.fetch bot, guild.id


bot.on "guildDelete", (guild) ->
  dbGuild = await getdbGuild guild
  unless dbGuild then return
  await dbGuild.destroy()
  logf LOG.DATABASE, "Guild #{formatGuild guild} removed"

bot.on "guildMemberAdd", (member) ->
  # I don't care about bots lol
  if member.user.bot
    logf LOG.MODERATION, "Bot #{formatUser member.user} just arrived"
    return
  
  # Praise shared auth !
  logf LOG.MODERATION, "User #{formatUser member.user} joined guild #{formatGuild member.guild}"
  await touchMember member

bot.on "guildMemberRemove", (member) ->
  # I don't care about bots lol
  if member.user.bot
    logf LOG.MODERATION, "Bot #{formatUser member.user} left guild #{formatGuild member.guild}"
    return
  logf LOG.MODERATION, "User #{formatUser member.user} left guild #{formatGuild member.guild}"
  dbUser = await getdbUser member.user
  unless dbUser then return

  # Yeeting dbUser out when it isn't present in any other server
  removeElement dbUser.servers, member.guild.id
  if dbUser.servers.length > 0
    await dbUser.update { servers: dbUser.servers }
    logf LOG.DATABASE, "User #{formatUser member.user} removed from guild #{formatGuild member.guild}"
  else
    await dbUser.destroy()
    logf LOG.DATABASE, "User #{formatUser member.user} removed"

  unless process.env.LOCAL
    unless member.guild.id is "672479260899803147" then return
    bye = BYEBYES[Math.floor (Math.random() * BYEBYES.length - 1e-6)]
    bye = bye.replace "{name}", member.displayName
    
    auRevoir = await bot.channels.fetch '672502429836640267'
    await auRevoir.send bye


bot.on "message", (msg) ->
  # I don't care about myself lol
  if msg.author.bot then return
  
  # We STILL don't care about messages that don't come from dms
  # Although we will care a bit later when introducing admin commands
  if msg.channel.type isnt "dm"
    if msg.author.id in TESTERS then syscall msg
    return
  
  # Note: we'll have to fetch every federated server
  # to see if the member exists in our discord network
  dbUser = await getdbUser msg.author
  unless dbUser then return

  unless await handleVerification gmailer, emailCH, dbUser, msg.author, msg.content
    # More stuff is gonna go here probably
    # like user commands to request your
    # decrypted data from the database
    if /^(get|give)\s+(me\s+)?(my\s+)?(user\s+)?data/i.test msg.content
      # nssData, standing for Not So Sensible Data
      nssData = { dbUser.dataValues... }
      nssData.id = decryptid nssData.id
      msg.author.send {
        embed:
          title: "Vos données sous forme YAML"
          description:
            """
            Voici vos données sous forme d'un objet YAML.
            ```yaml
            #{YAML.stringify nssData}```
            """
          color: 0x34d9ff
          footer: FOOTER
      }
    else
      msg.author.send "Vous êtes vérifié(e), vous n'avez plus rien à craindre."


bot.on "messageReactionAdd", (reaction, user) ->
  # I still don't care about myself lol
  if user.bot then return
  
  if reaction.partial then await reaction.fetch()
  # I don't care about anything else apart from DMs
  if reaction.message.channel.type isnt "dm" then return
  dbUser = await getdbUser user
  unless dbUser then return
  
  unless reaction.message.id is dbUser.reactor then return
  
  switch reaction.emoji.name
    when "⏪"
      dbUser.code = null
      dbUser.email = null
      await dbUser.save()
      await user.send {
        embed:
          title: "Adresse mail effacée"
          description: "Vous pouvez désormais renseigner une nouvelle adresse mail."
          color: 0x32ff64
          footer: FOOTER
      }
    when "🔁"
      gmailer.verifyEmail dbUser, user, dbUser.email, emailCH
    else return

  setTimeout (-> reaction.message.delete()), 3000



bot.on "guildMemberUpdate", (_, member) ->
  levelRoles = ["licence_1", "licence_2", "licence_3", "master_1", "master_2", "doctorat", "professeur"]
  if levelRoles.some (lr) -> member.roles.cache.has SERVERS.main.roles[lr]
    member.roles.remove SERVERS.main.roles.indecis



bot.login process.env.SORBOT_TOKEN
