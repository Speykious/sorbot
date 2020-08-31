{ logf, LOG, formatCrisis } = require "../logging"

verifyEmail = (dbUser, user, email) ->
  try
    dbUser.email = email
    dbUser.save()
  catch err
    logf LOG.MAIL, (formatCrisis "Mail Validation", err)

module.exports = verifyEmail
