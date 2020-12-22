require "dotenv-flow"
.config()

{ Client } = require "discord.js"

{ logf, LOG, botCache } = require "./logging"
{ SERVERS, GUILDS } = require "./constants"

regexinator = /^Email (`.+` )\(code .+\) saved for user .+$/

bot = new Client {
  disableMentions: "everyone"
}

bot.on "ready", ->
  console.log "TIME TO ERASE TRACES OF EMAILS"
  botCache.bot = bot
  await bot.user.setPresence {
    activity:
      type: "PLAYING"
      name: "Oops, I dropped it again ~"
      url: "https://gitlab.com/Speykious/sorbot"
  }
  
  GUILDS.LOGS = await bot.guilds.fetch SERVERS.logs.id
  
  console.log "Fetching #email..."
  chemail = GUILDS.LOGS.channels.resolve "755792774359679037"
  console.log "Fetching messages..."
  messages = []
  lastMessageId = "781069634757328936"
  loop
    messages = await Promise.all (
      (await chemail.messages.fetch { limit: 100, before: lastMessageId })
      .filter ({ content }) -> regexinator.test content
      .map (message) ->
        [_, replaceTarget, _, _, _] = message.content.match regexinator
        newContent = message.content.replace replaceTarget, ""
        await message.edit newContent
        console.log newContent
        return message)
    unless messages.length then break
    lastMessageId = messages[messages.length - 1].id

  bot.destroy()
  

bot.login process.env.SORBOT_TOKEN_REAL
