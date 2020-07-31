{ rgb24, bold, red, underline } = require "ansi-colors-ts"
{ authorize }                   = require "./mail/gindex"
gmain                           = require "./mail/gmain"
{ Client }                      = require "discord.js"
{ relative, delay, sendError,
  readf, CROSSMARK }            = require "./utils"
YAML                            = require "yaml"

require "dotenv-flow"
.config()

bot = new Client {
  disableMentions: "everyone"
}

bot.on "ready", () ->
  console.log (rgb24 0xAE6753) bold "Ready to... sip. ☕"
  ###
  bot.channels.cache.get "672498488646434841"
  .send "**GO BACK TO WORK, I NEED TO GET DONE** <@&672480366266810398>"
  ###

  try # Load client secrets from a local file.
    content = readf "../credentials.yaml"
    # Authorize a client with credentials, then call the Gmail API.
    authorize (YAML.parse content), gmain
  catch err
    console.log (red CROSSMARK + " Error loading #{underline "credentials.yaml"}:"), err
  
  ### # was testing embeds
  bot.channels.cache.get "672514494903222311"
  .send {
    embed:
      title: "Testing in progress..."
      description: "Hello I'm a description"
      footer:
        text: "Hello I'm a footer"
        icon_url: "https://gitlab.com/Speykious/sorbot-3/-/raw/master/resources/blackorbit-sorbonne-logo.png"
  }
  ###
  

if process.env.LOCAL
then bot.login process.env.SLOCAL_TOKEN
else bot.login process.env.SORBOT_TOKEN
