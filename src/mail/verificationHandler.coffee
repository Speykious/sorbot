{ GUILDS, SERVERS, FOOTER, USER_TYPES } = require "../constants"
{ logf, LOG, formatUser }               = require "../logging"

# dbUser {User}        - The user to verify in the database
# member {GuildMember} - The member to verify
# verifier {string}    - The discord tag of the one who verified the member
verifyUser = (dbUser, member, verifier) ->
  if dbUser.reactor
    dmChannel = await member.user.createDM()
    dmChannel.messages.delete dbUser.reactor
    dbUser.reactor = null
  dbUser.code = null
  dbUser.save()
  
  smr = SERVERS.main.roles
  await member.roles.set [smr.membre]
  ut = dbUser.userType
  if ut & USER_TYPES.PROFESSOR then await member.roles.add smr.professeur
  if ut & USER_TYPES.STUDENT   then await member.roles.add smr.indecis
  if ut & USER_TYPES.GUEST     then await member.roles.add smr.squatteur
  if ut & USER_TYPES.FORMER    then await member.roles.add smr.ancien
  
  unless verifier then verifier = member.client.user.tag
  adverb = if verifier is member.client.user.tag
  then "automatically" else "manually"
  
  await member.user.send {
    embed:
      title: "Vous êtes vérifié.e"
      description:
        """
        Vous avez désormais le rôle @Membre sur le serveur.
        N'oubliez pas de choisir vos rôles dans le salon #rôles.
        Tant que vous n'aurez pas choisi votre rôle d'année d'études,
        vous aurez aussi le rôle @Indécis (sauf si vous avez le rôle Professeur, Ancien ou Squatteur).
        """
      fields: [{
        name: "Verified #{adverb} by"
        value: "<:yupright:688760843462377483> #{verifier} <:yupleft:688760831110021121>"
      }]
      color: 0x32ff64
      footer: FOOTER
  }
  
  logf LOG.MODERATION, "User #{formatUser member.user} has been #{adverb} verified by #{verifier}"



handleVerification = (gmailer, emailCH, dbUser, user, content) ->
  # Remember from SorBOT 2:
  # - If no email, we try to register the email
  # - If email and code, we verify the code
  # - If email but no code, the user is verified
  if dbUser.email is null # Email verification stuff
    await gmailer.verifyEmail dbUser, user, content, emailCH
  else if dbUser.code # Code verification stuff
    if content == dbUser.code
      member = GUILDS.MAIN.member user # Oh waow didn't know I could do that
      await verifyUser dbUser, member
    else
      await user.send {
        embed:
          title: "Code invalide"
          description: "**Erreur :** Le code n'est pas le bon. Réessayez."
          color: 0xff3232
          footer: FOOTER
      }
  
  # The return value represents whether verification has been handled
  else return no
  return yes

module.exports = { handleVerification, verifyUser }
