import { TextChannel, DMChannel, NewsChannel } from "discord.js"
import * as path from "path"

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
