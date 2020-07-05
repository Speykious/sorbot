import { Client } from "discord.js"

console.log "coffee yeet, yeet coffee"

sendCoffee = (channel, coffeeString, msDelay = 5000) =>
  coffeeString = "Coffee: " + coffeeString
  coffeeMsg = await channel
    .send coffeeString
    .catch () => Promise.resolve()
  if coffeeMsg then coffeeMsg.delete { timeout: msDelay }
  return Promise.resolve coffeeMsg

export { sendCoffee }