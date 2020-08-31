{ logf, LOG, formatCrisis } = require "../logging"

verifyEmail = (dbUser, user, email) ->
  try
    dbUser.email = email
    await dbUser.save()
  catch errs
    messages = errs.map (e) -> e.message
    logf LOG.MAIL, (formatCrisis "Mail Validation", messages)

module.exports = verifyEmail
