{ getdbGuild, parseAssocs } = require "./db/dbhelpers"
{ decryptid }               = require "./encryption"

updateMemberRoles = (member, dbUser) ->
  dbGuild = await getdbGuild member.guild
  unless dbGuild then return dbUser

  assocs = parseAssocs dbGuild.roles
  promises = assocs.map ([roleid, roletag]) ->
    return if roletag in dbUser.roletags
    then member.roles.add roleid
    else member.roles.remove roleid
  
  return Promise.all promises

updateRoles = (bot, dbUser) ->
  id = decryptid dbUser.id
  promises = dbUser.servers.map (server) ->
    guild = bot.guilds.fetch server
    member = guild.members.fetch id
    return updateMemberRoles member, dbUser
  
  return Promise.all promises

module.exports = {
  updateMemberRoles
  updateRoles
}