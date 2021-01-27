{ User, FederatedMetadata } = require "./initdb"
{ encryptid }               = require "../encryption"
{ logf, LOG, formatCrisis
  formatUser, formatGuild } = require "../logging"
{ setAdd, removeElement }   = require "../helpers"

getdbUser = (user, mode) ->
  try
    dbUser = await User.findByPk encryptid user.id
    unless dbUser then throw "User #{formatUser user} doesn't exist in our database"
    return dbUser
  catch err
    unless mode is "silent" then logf LOG.DATABASE, (formatCrisis "Existential", err)
    return undefined

getdbGuild = (guild, mode) ->
  try
    dbGuild = await FederatedMetadata.findByPk guild.id
    unless dbGuild then throw "Guild #{formatGuild guild} doesn't exist in our database"
    return dbGuild
  catch err
    unless mode is "silent" then logf LOG.DATABASE, (formatCrisis "Existential", err)
    return undefined

parseAssocs = (lines) ->
  lines.split "\n"
  .map (line) -> line.split ":"

stringifyAssocs = (assocs) ->
  assocs.map (assoc) -> assoc.join ":"
  .join "\n"

addRoletag = (dbUser, roletag) ->
  setAdd dbUser.roletags, roletag

removeRoletag = (dbUser, roletag) ->
  removeElement dbUser.roletag, roletag

module.exports = {
  getdbUser
  getdbGuild
  parseAssocs
  stringifyAssocs
  addRoletag
  removeRoletag
}
