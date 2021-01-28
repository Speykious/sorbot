{ FOOTER } = "../constants"

sendReactor = (user, dbUser) ->
  # Introducing: Back to the Reactions, 2020
  reactor = await user.dmChannel.send {
    embed:
      title: "Un problème ?"
      description:
        """
        ⏪ - Changer votre adresse mail
        🔁 - Renvoyer un nouveau code de confirmation
        """
      color: 0x34d9ff
      footer: FOOTER
  }
  # Change, or send email again
  await Promise.all ["⏪", "🔁"].map (e) -> reactor.react e
  
  dbUser.reactor = reactor.id
  dbUser.save()

module.exports = sendReactor
