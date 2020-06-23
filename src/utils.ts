import { TextChannel, DMChannel, NewsChannel, Message } from "discord.js"
import * as path from "path"

export const relative = (s: string): string => path.resolve(__dirname, s)
export const delay = async (ms: number): Promise<void> =>
	new Promise((resolve) => setTimeout(resolve, ms))

export const sendError = async (
	channel: TextChannel | DMChannel | NewsChannel,
	errorString: string,
	msDelay = 5000
): Promise<void | Message> => {
	const errorMsg: void | Message = await channel
		.send(errorString)
		.catch(() => Promise.resolve())
	if (errorMsg) errorMsg.delete({ timeout: msDelay })
	return Promise.resolve(errorMsg)
}
