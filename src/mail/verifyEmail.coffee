{ logf, LOG, formatCrisis, formatUser } = require "../logging"

# Sends an email using a request object.
#
# request:
#   from:    string
#   to:      string
#   subject: string
#   content: string
sendEmail = (gmail, request) ->
  # | You can use UTF-8 encoding for the subject using the method below.
  # | You can also just use a plain string if you don't need anything fancy.
  # Hmmmmm... I think I'll let that be there 🤔
  utf8Subject = "=?utf-8?B?#{(Buffer.from request.subject).toString "base64"}?="
  message =
    """
    From: #{request.from}
    To: #{request.to}
    Content-Type: text/html charset=utf-8
    MIME-Version: 1.0
    Subject: #{utf8Subject}
    
    html: #{request.content}
    """

  # The body needs to be base64url encoded.
  encodedMessage = Buffer.from message
    .toString "base64"
    .replace /\+/g, "-"
    .replace /\//g, "_"
    .replace /=+$/, ""

  res = await gmail.users.messages.send {
    userId: "me"
    requestBody:
      raw: encodedMessage
  }
  console.log message
  console.log "Sent email: ", res.data
  return res.data


# Validates the email address through Sequelize
# before sending the confirmation code.
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
  await sendEmail @gmail, {
    from: "bot.sorbonne.jussieu@gmail.com"
    to: email
    subject: "Code de confirmation"
    content: """
             Ceci est un <b>test</b>.
             J'espère que ça marche 🤔
             """
  }

module.exports = verifyEmail
