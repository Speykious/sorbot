{ User, FederatedMetadata }                          = require "./initdb"
{ encryptid }                                        = require "../encryption"
{ logf, LOG, formatCrisis, formatUser, formatGuild } = require "../logging"

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

module.exports = {
  getdbUser
  getdbGuild
}
