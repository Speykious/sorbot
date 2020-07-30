{ green, bold, red }           = require "ansi-colors-ts"
{ authorize }                  = require "./mail/gindex"
gmain                          = require "./mail/gmain"
{ Client }                     = require "discord.js"
{ relative, delay, sendError } = require "./utils"
YAML                           = require "yaml"
fs                             = require "fs"

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

  # Load client secrets from a local file.
  fs.readFile (relative "../credentials.yaml"), (err, content) ->
    if (err)
      return console.log (bold red "Error loading client secret file:"), err
    # Authorize a client with credentials, then call the Gmail API.
    authorize (YAML.parse content), gmain

if process.env.LOCAL
then bot.login process.env.SLOCAL_TOKEN
else bot.login process.env.SORBOT_TOKEN
