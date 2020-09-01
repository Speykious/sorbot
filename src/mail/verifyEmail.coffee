{ logf, LOG, formatCrisis, formatUser } = require "../logging"

verifyEmail = (dbUser, user, email) ->
  try # All the Sequelize validation process goes here
    dbUser.email = email
    await dbUser.save()
    logf LOG.MAIL, "Email {#ff8032-fg}#{email}{/} saved for user", formatUser user
  catch valerr
    messages = valerr.errors.map (e) -> e.message
    logf LOG.MAIL, (formatCrisis "Mail Validation", messages)
    return
  
  # Send mail here

module.exports = verifyEmail
