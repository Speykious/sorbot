{ updateMemberRoles } = require "./roles"
{ sendDmPage }        = require "./frontend/pageHandler"
RTFM                  = require "./frontend/RTFM"
{ User }              = require "./db/initdb"
{ getdbUser }         = require "./db/dbhelpers"
{ logf, LOG }         = require "./logging"

# Fetches a member and increments its servers, or creates a new one from the database
touchMember = (member) ->
  dbUser = await getdbUser member.user, "silent"
  if dbUser
    # Add the current server to the member's database field
    unless member.guild.id in dbUser.servers
      dbUser.servers.push member.guild.id
      await dbUser.update { servers: dbUser.servers }
  else
    page = RTFM.getPage "welcomedm"
    pagemsg = await sendDmPage page, member.user
    unless pagemsg then return null # no need to send an error msg
    dbUser = await User.create {
      id: member.user.id
      roletags: ["unverified"]
      servers: [member.guild.id]
    }

    logf LOG.DATABASE, "New user #{formatUser member.user} has been added to the database"

  # Add available roles from the guild
  updateMemberRoles member, dbUser
  
  return dbUser

module.exports = touchMember