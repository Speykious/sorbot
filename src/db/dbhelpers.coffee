{ User }                                = require "./initdb"
{ encryptid }                           = require "../encryption"
{ logf, LOG, formatCrisis, formatUser } = require "../logging"

getdbUser = (user) ->
  try # Manages the fetching of menuState
    dbUser = await User.findByPk encryptid user.id
    unless dbUser then throw "User #{formatUser user} doesn't exist in our database"
    return dbUser
  catch err
    # In this block we have to tell the user that they are not registered
    # in our database and that they should contact us or something
    logf LOG.DATABASE, (formatCrisis "Existential", err)
    return undefined

module.exports = {
  getdbUser
}
