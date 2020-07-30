{ green, bold, red, underline }       = require "ansi-colors-ts"
{ authorize }                         = require "./mail/gindex"
gmain                                 = require "./mail/gmain"
{ Client }                            = require "discord.js"
{ relative, delay, sendError, readf } = require "./utils"
YAML                                  = require "yaml"

require "dotenv-flow"
.config()

bot = new Client {
  disableMentions: "everyone"
}

bot.on "ready", () ->
  console.log green "Ready to... sip."
  ###
  bot.channels.cache.get "672498488646434841"
  .send "**GO BACK TO WORK, I NEED TO GET DONE** <@&672480366266810398>"
  ###

  try # Load client secrets from a local file.
    content = readf "../credentials.yaml"
    # Authorize a client with credentials, then call the Gmail API.
    authorize (YAML.parse content), gmain
  catch err
    console.log (bold red "Error loading #{underline "credentials.yaml"}:"), err
  
  ### # was testing embeds
  bot.channels.cache.get "672514494903222311"
  .send {
    embed:
      title: "Testing in progress..."
      description: "Hello I'm a description"
      #timestamp: new Date()
      footer: "Hello I'm a footer"
  }
  ###

if process.env.LOCAL
then bot.login process.env.SLOCAL_TOKEN
else bot.login process.env.SORBOT_TOKEN
