import { Client, TextChannel } from "discord.js"
import {} from "./utils"

import * as dotenvFlow from 'dotenv-flow'
dotenvFlow.config()

const bot = new Client({
  disableMentions: "everyone"
})

bot.on("ready", () => {
  console.log("Ready to yeet.")
  // const tc = bot.channels.cache.get("672498488646434841") as TextChannel
  // tc.send(`Voici votre fichier \`.env\` (à inclure dans votre repo en local, il sera ignoré par \`git\`):`);
})

if (process.env.LOCAL)
  bot.login(process.env.SLOCAL_TOKEN)
else bot.login(process.env.SORBOT_TOKEN)
