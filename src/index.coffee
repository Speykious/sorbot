{ rgb24, bold, red, underline,
  green, blue, cyan, yellow }   = require "ansi-colors-ts"
{ authorize }                   = require "./mail/gindex"
gmain                           = require "./mail/gmain"
{ Client }                      = require "discord.js"
{ relative, delay, sendError,
  readf, CROSSMARK, CHECKMARK,
  templog, templogln }          = require "./utils"
YAML                            = require "yaml"

require "dotenv-flow"
.config()

bot = new Client {
  disableMentions: "everyone"
  partials: ['MESSAGE', 'CHANNEL', 'REACTION']
}

bot.on "ready", () ->
  console.log (rgb24 0xAE6753) bold "Ready to... sip. ☕"

  try # Load client secrets from a local file.
    content = readf "../credentials.yaml"
    # Authorize a client with credentials, then call the Gmail API.
    authorize (YAML.parse content), gmain
  catch err
    console.log (red CROSSMARK + " Error loading #{underline "credentials.yaml"}:"), err
  
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

bot.on "messageReactionAdd", (reaction, user) ->
  console.log """
              #{bold green "A new reaction was added!"}
              Relevant information:
                - emoji   of the reaction: #{cyan   String reaction._emoji.name}
                - user    of the reaction: #{blue   String user.id}
                - message of the reaction: #{blue   String reaction.message.id}
                - source  of the reaction: #{yellow String reaction.message.channel.type}
              """

bot.on "messageReactionRemove", (reaction, user) ->
  console.log """
              #{bold red "A new reaction was removed!"}
              Relevant information:
                - emoji   of the reaction: #{cyan   String reaction._emoji.name}
                - user    of the reaction: #{blue   String user.id}
                - message of the reaction: #{blue   String reaction.message.id}
                - source  of the reaction: #{yellow String reaction.message.channel.type}
              """

if process.env.LOCAL
then bot.login process.env.SLOCAL_TOKEN
else bot.login process.env.SORBOT_TOKEN
