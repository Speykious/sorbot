{ Client } = require "discord.js"
{ relative, delay, sendError } = require "./utils"

require 'dotenv-flow'
.config()

bot = new Client {
  disableMentions: "everyone"
}

bot.on "ready", () ->
  console.log "Ready to... sip."
  
  bot.channels.cache.get "672498488646434841"
  .send "GO BACK TO WORK, I NEED TO GET DONE <@&672480366266810398>"
  

if process.env.LOCAL
then bot.login process.env.SLOCAL_TOKEN
else bot.login process.env.SORBOT_TOKEN
