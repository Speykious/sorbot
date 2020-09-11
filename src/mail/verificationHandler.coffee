{ GUILDS, SERVERS, FOOTER } = require "../constants"
{ logf, LOG, formatUser }   = require "../logging"

handleVerification = (gmailer, dbUser, msg) ->
  # Remember from SorBOT 2:
  # - If no email, we try to register the email
  # - If email and code, we verify the code
  # - If email but no code, the user is verified
  if dbUser.email is null # Email verification stuff
    await gmailer.verifyEmail dbUser, msg.author, msg.content, emailCH
  else if dbUser.code # Code verification stuff
    if msg.content == dbUser.code
      dbUser.code = null
      dbUser.save()
      member = await GUILDS.MAIN.members.fetch msg.author.id
      member.roles.set [SERVERS.main.roles.membre, SERVERS.main.roles.indecis]
      
      await msg.channel.send {
        embed:
          title: "Vous êtes vérifié.e"
          description:
            """
            Vous avez désormais le rôle @Membre sur le serveur.
            N'oubliez pas de choisir vos rôles dans le salon #rôles.
            Tant que vous n'aurez pas choisi votre rôle d'année d'études,
            vous aurez aussi le rôle @Indécis.
            """
          color: 0x32ff64
          footer: FOOTER
      }
      logf LOG.MODERATION, "User #{formatUser member.user} has been verified"
    else
      await msg.channel.send {
        embed:
          title: "Code invalide"
          description: "**Erreur :** Le code n'est pas le bon. Réessayez."
          color: 0xff3232
          footer: FOOTER
      }
  
  # The return value represents whether verification has been handled
  else return no 
  return yes

module.exports = handleVerification
