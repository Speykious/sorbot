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
{ relative, delay, readf }              = require "./helpers"
{ logf, LOG, formatCrisis, formatUser } = require "./logging"
{ CROSSMARK, SERVERS,
  GUILDS, TESTERS, FOOTER }             = require "./constants"
{ encryptid }                           = require "./encryption"

loading.step "Loading gmailer and email crisis handler..."
GMailer                                 = require "./mail/gmailer"
EmailCrisisHandler                      = require "./mail/crisisHandler"
handleVerification                      = require "./mail/verificationHandler"

loading.step "Loading frontend functions..."
syscall                                 = require "./frontend/syscall"
{ mdir, getMenu, sendDmMenu }           = require "./frontend/menu-handler"

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

loading.step "Instantiating new GMailer and EmailCrisisHandler..."
gmailer = new GMailer ["readonly", "modify", "compose", "send"], "credentials.yaml"

# - slowT          {number}  - period for the slow read mode, in seconds
# - fastT          {number}  - period for the fast read mode, in seconds
# - maxThreads     {number}  - Maximum number of threads globally
# - maxThreadsSlow {number}  - Maximum number of threads only for slow mode
# - maxThreadsFast {number}  - Maximum number of threads only for fast mode
# - guild          {Guild}   - The main discord guild to handle the crisis with
# - gmailer        {GMailer} - The gmailer to read the email threads with
# - embedUEC       {Embed}   - The embed error report for Unread Existential Crisis
# - embedUSC       {Embed}   = The embed error report for Unread Sorbonne Crisis
emailCH = new EmailCrisisHandler {
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
        Le sujet du mail doit obligatoirement être votre tag discord, à savoir de la forme `pseudo#1234`, sinon il nous sera impossible de vous vérifier.
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
logf LOG.INIT, "{#ae6753-fg}Preparing the cup of coffee...{/}"

bot.on "ready", ->
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
  setTimeout ( ->
    console.log ""
    emailCH.guild = GUILDS.MAIN
    emailCH.gmailer = gmailer
    emailCH.activate()
  ), 100


bot.on "guildMemberAdd", (member) ->
  # For now we only care about the main server.
  # Federated server autoverification coming soon™
  if member.guild.id isnt GUILDS.MAIN.id then return
  
  logf LOG.MODERATION, "Adding user #{formatUser member.user}"
  await member.roles.add SERVERS.main.roles.non_verifie
  
  welcome = "welcomedm"
  menu = getMenu welcome
  menumsg = await sendDmMenu menu, member.user
  unless menumsg then return # no need to send an error msg
  
  # Add new entry in the database
  await User.create {
    id: member.user.id
    userType: 0
  }
  
  logf LOG.DATABASE, "User #{formatUser member.user} added"


bot.on "guildMemberRemove", (member) ->
  logf LOG.MODERATION, "Removing user #{formatUser member.user}"
  dbUser = await getdbUser member.user
  unless dbUser then return
  # Yeeting dbUser out when someone leaves
  await dbUser.destroy()
  logf LOG.DATABASE, "User #{formatUser member.user} removed"



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
  
  unless handleVerification gmailer, emailCH, dbUser, msg
    # More stuff is gonna go here probably,
    # like user commands to request your
    # decrypted data from the database
    msg.channel.send "Vous êtes vérifié(e), vous n'avez plus rien à craindre. *(more options coming soon™)*"


bot.login process.env.SORBOT_TOKEN
