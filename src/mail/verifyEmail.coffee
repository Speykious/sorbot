{ GUILDS, FOOTER }                      = require "../constants"
{ logf, LOG, formatCrisis, formatUser } = require "../logging"
{ readf }                               = require "../helpers"
{ UniqueConstraintError }               = require "sequelize"
sendEmail                               = require "./sendEmail"
sendReactor                             = require "../frontend/sendReactor"

codeset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
generateCode = (l) ->
  c = ""
  while l > 0
    c += codeset[Math.floor Math.random() * (codeset.length - 0.001)]
    l--
  return c


# Validates the email address through Sequelize
# before sending the confirmation code.
verifyEmail = (dbUser, user, email, crisisHandler) ->
  try # All the Sequelize validation process goes here
    dbUser.email = email
    dbUser.code = generateCode 6
    await dbUser.save()
    logf LOG.EMAIL, "Email (with code `#{dbUser.code}`) saved for user", formatUser user

  catch valerr
    if valerr instanceof UniqueConstraintError
      await user.dmChannel.send {
        embed:
          title: "Erreur de Validation"
          description: "L'adresse mail `#{email}` est déjà utilisée par un autre membre."
          color: 0xff3232
          footer: FOOTER
      }
      
      logf LOG.WARNING, {
        embed:
          title: "UNIQUE CONSTRAINT WARNING"
          description: "User <@!#{user.id}> (__#{user.id}__) tried to use an email address which is already used!"
          fields: [{
            name: "Email Address"
            value: email
          }]
          color: 0xffee32
          footer: FOOTER
      }
      
      return
    
    messages = valerr.errors.map((e) -> e.message).reverse()
    logf LOG.EMAIL, (formatCrisis "Email Validation",
      "For user #{formatUser user}: `#{messages[0]}`")
    
    await user.dmChannel.send {
      embed:
        title: "Erreur de Validation"
        description: messages[0]
        color: 0xff3232
        footer: FOOTER
    }
    
    return
  
  await sendEmail @gmail, {
    from: "SorBOT 3 <bot.sorbonne.jussieu@gmail.com>"
    to: email
    subject: "Discord - Code de confirmation"
    text: readf "resources/confirmation-email.txt"
      .replace(/\{tag\}/g, user.tag)
      .replace(/\{code\}/g, dbUser.code)
    html: readf "resources/confirmation-email.html"
      .replace(/\{tag\}/g, user.tag)
      .replace(/\{code\}/g, dbUser.code)
  }

  await user.dmChannel.send {
    embed:
      title: "Mail de confirmation envoyé"
      description: "Un mail de confirmation a été envoyé à l'adresse `#{email}`."
      color: 0x32ff64
      footer: FOOTER
  }
  
  await sendReactor user, dbUser
  crisisHandler.request()

module.exports = verifyEmail
