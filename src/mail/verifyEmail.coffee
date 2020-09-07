{ logf, LOG, formatCrisis, formatUser } = require "../logging"
{ readf }                               = require "../helpers"

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
    MIME-Version: 1.0
    From: #{request.from}
    To: #{request.to}
    Subject: #{utf8Subject}
    Content-Type: multipart/alternative; boundary="boundary-text"

    --boundary-text
    Content-Type: text/plain; charset="utf-8"

    #{request.text}
    --boundary-text
    Content-Type: text/html; charset="utf-8"
    
    #{request.html}--boundary-text--
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
  
  logf LOG.EMAIL "Sent email:", res.data
  return res.data


# Validates the email address through Sequelize
# before sending the confirmation code.
verifyEmail = (dbUser, user, email) ->
  try # All the Sequelize validation process goes here
    dbUser.email = email
    await dbUser.save()
    logf LOG.EMAIL, "Email {#ff8032-fg}#{email}{/} saved for user", formatUser user
  catch valerr
    messages = valerr.errors.map (e) -> e.message
               .reverse()
    logf LOG.EMAIL, (formatCrisis "Mail Validation", messages)
    return
  
  # Send mail here
  await sendEmail @gmail, {
    from: "SorBOT 3 <bot.sorbonne.jussieu@gmail.com>"
    to: email
    subject: "Code de confirmation"
    text: readf "resources/confirmation-email.txt"
    html: readf "resources/confirmation-email.html"
  }

module.exports = verifyEmail
