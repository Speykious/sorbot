require "dotenv-flow"
.config()

{ join } = require "path"
YAML     = require "yaml"
{ Client } = require "discord.js"

{ logf, LOG, botCache } = require "./logging"
{ SERVERS,
  GUILDS, TESTERS, FOOTER }   = require "./constants"


bot = new Client {
  disableMentions: "everyone"
}

bot.on "ready", ->
  console.log "Ready to print the QR code :)"
  botCache.bot = bot
  logf LOG.INIT, "Don't mind me, just creating a cool embed for the QR code invite :)"
  
  GUILDS.MAIN = await bot.guilds.fetch SERVERS.main.id
  GUILDS.LOGS = await bot.guilds.fetch SERVERS.logs.id

bot.on "message", (msg) ->
  unless /^(system[\s-]call|sc)\s*:\s*generate\s+qr[\s-]code\s+element/i.test msg.content then return
  unless msg.author.id in TESTERS
    msg.channel.send "<@!#{msg.author.id}> No."
    return
  
  msg.channel.send {
    embed:
      title: "QR code d'invitation du serveur"
      description:
        """
        Ceci est la **version QR code** du lien d'invitation du serveur.
        Ne le scannez pas avec Discord (ainsi que tout autre QR code par ailleurs) car ça ne marchera pas : le scanneur QR code de Discord ne peut être utilisé que pour se connecter plus convenablement sur votre ordinateur via votre téléphone.
        Au lieu de cela, utilisez un scanneur de QR code quelconque tel que <:yupright:688760843462377483> **[Binary Eye](https://play.google.com/store/apps/details?id=de.markusfisch.android.binaryeye)** <:yupleft:688760831110021121> disponible sur Android, ou bien certaines caméras de base sur certains téléphones, tels que les iPhones avec une version récente d'iOS.
        """
      image:
        url: "https://i.imgur.com/3jSYncY.png"
      color: 0x34d9ff
      footer: FOOTER
  }


bot.login process.env.SORBOT_TOKEN_REAL
