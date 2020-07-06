import * as path from 'path'
import { Client, TextChannel, DMChannel, NewsChannel } from "discord.js"

import * as dotenvFlow from 'dotenv-flow'
dotenvFlow.config()

export const relative = (s: string) => path.resolve(__dirname, s)
export const delay = async (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms))

export const sendError = async (
  channel: TextChannel | DMChannel | NewsChannel,
  errorString: string,
  msDelay: number = 5000
) => {
  const errorMsg = await channel
    .send(errorString)
    .catch(() => Promise.resolve())
  if (errorMsg) errorMsg.delete({ timeout: msDelay })
  return Promise.resolve(errorMsg)
}

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
