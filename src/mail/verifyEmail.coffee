{ GUILDS }                              = require "../constants"
{ logf, LOG, formatCrisis, formatUser } = require "../logging"
{ readf }                               = require "../helpers"
{ UniqueConstraintError }               = require "sequelize"
sendEmail                               = require "./sendEmail"



# Validates the email address through Sequelize
# before sending the confirmation code.
verifyEmail = (dbUser, user, email) ->
  try # All the Sequelize validation process goes here
    dbUser.email = email
    await dbUser.save()
    logf LOG.EMAIL, "Email {#ff8032-fg}#{email}{/} saved for user", formatUser user

  catch valerr
    if valerr instanceof UniqueConstraintError
      logf LOG.EMAIL, (formatCrisis "Mail Duplication", valerr.original.detail)
      
      await user.dmChannel.send {
        embed:
          title: "Erreur de Validation"
          description: "L'adresse mail `#{email}` est déjà utilisée par un autre membre."
          color: 0xff3232
      }
      
      chbot = GUILDS.MAIN.channels.cache.get "672514494903222311"
      await chbot.send {
        embed:
          title: "UNIQUE CONSTRAINT WARNING"
          description: "User <@!#{user.id}> (__#{user.id}__) tried to use an email address which is already used!"
          fields: [{
            name: "Email Address"
            value: email
          }]
          color: 0xffee32
      }
      
      return

    messages = valerr.errors.map((e) -> e.message).reverse()
    logf LOG.EMAIL, (formatCrisis "Mail Validation", messages[0])
    
    await user.dmChannel.send {
      embed:
        title: "Erreur de Validation"
        description: messages[0]
        color: 0xff3232
    }
    
    return
  
  # Send mail here
  await sendEmail @gmail, {
    from: "SorBOT 3 <bot.sorbonne.jussieu@gmail.com>"
    to: email
    subject: "Discord - Code de confirmation"
    text: readf "resources/confirmation-email.txt"
      .replace(/\{tag\}/g, user.tag)
      .replace(/\{code\}/g, somecode)
    html: readf "resources/confirmation-email.html"
  }

  await user.dmChannel.send {
    embed:
      title: "Mail de confirmation envoyé"
      description: "Un mail de confirmation a été envoyé à l'adresse `#{email}`."
      color: 0x32ff64
  }

module.exports = verifyEmail
