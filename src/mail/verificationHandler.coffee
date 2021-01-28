{ GUILDS, SERVERS, FOOTER, USER_TYPES } = require "../constants"
{ logf, LOG, formatUser }               = require "../logging"
{ addRoletag, removeRoletag }           = require "../db/dbhelpers"
{ updateRoles }                         = require "../roles"
sendReactor                             = require "../frontend/sendReactor"

# dbUser {User}        - The user to verify in the database
# member {GuildMember} - The member to verify
# verifier {string}    - The discord tag of the one who verified the member
verifyUser = (dbUser, bot, user, verifier) ->
  if dbUser.reactor
    dmChannel = await user.createDM()
    dmChannel.messages.delete dbUser.reactor
    dbUser.reactor = null
  dbUser.code = null

  console.log "roletags:", dbUser.roletags
  addRoletag dbUser, "member"
  console.log "roletags:", dbUser.roletags
  removeRoletag dbUser, "unverified"
  console.log "roletags:", dbUser.roletags
  dbUser.save { fields: ["reactor", "code", "roletags"] }

  # Update roles in every guild the user is in
  await updateRoles bot, dbUser

  unless verifier then verifier = bot.user.tag
  adverb = if verifier is bot.user.tag
  then "automatically" else "manually"
  
  await user.send {
    embed:
      title: "Vous êtes vérifié.e"
      description:
        """
        Vous avez désormais le rôle @Membre sur le serveur.
        N'oubliez pas de choisir vos rôles dans le salon #rôles s'il y en a.
        """
      fields: [{
        name: "Verified #{adverb} by"
        value: "<:yupright:688760843462377483> #{verifier} <:yupleft:688760831110021121>"
      }]
      color: 0x32ff64
      footer: FOOTER
  }
  
  logf LOG.MODERATION, "User #{formatUser user} has been #{adverb} verified by #{verifier}"



handleVerification = (gmailer, emailCH, dbUser, user, content) ->
  # We don't handle verification for users with the guest flag
  # as they are already verified
  if "guest" in dbUser.roletags then return no
  
  # Remember from SorBOT 2:
  # - If no email, we try to register the email
  # - If email and code, we verify the code
  # - If email but no code, the user is verified
  if dbUser.email is null # Email verification stuff
    await gmailer.verifyEmail dbUser, user, content, emailCH
  else if dbUser.code # Code verification stuff
    if content is dbUser.code
      # `GUILDS.MAIN.member` "Oh waow didn't know I could do that"
      await verifyUser dbUser, emailCH.bot, user
    else
      if dbUser.reactor
        await user.send {
          embed:
            title: "Code invalide"
            description: "**Erreur :** Le code n'est pas le bon. Réessayez."
            color: 0xff3232
            footer: FOOTER
        }
      else
        await user.send {
          embed:
            title: "Code invalide"
            description:
              """
              **Erreur :** Le code n'est pas le bon.
              Il semblerait que vous n'ayez pas de menu reactor.
              Nous vous en envoyons un de suite !
              """
            color: 0xff3232
            footer: FOOTER
        }
        await sendReactor user, dbUser
  
  # The return value represents whether verification has been handled
  else return no
  return yes

module.exports = { handleVerification, verifyUser }
