{ getdbGuild, parseAssocs } = require "./db/dbhelpers"
{ decryptid }               = require "./encryption"

updateMemberRoles = (member, dbUser) ->
  dbGuild = await getdbGuild member.guild
  unless dbGuild then return dbUser

  promises = dbGuild.roleassocs.map ([roleid, roletag]) ->
    return if roletag in dbUser.roletags
    then member.roles.add roleid
    else member.roles.remove roleid
  
  return Promise.all promises

updateRoles = (bot, dbUser) ->
  id = decryptid dbUser.id
  promises = dbUser.servers.map (server) ->
    guild = await bot.guilds.fetch server
    member = await guild.members.fetch id
    return await updateMemberRoles member, dbUser
  
  return Promise.all promises

module.exports = {
  updateMemberRoles
  updateRoles
}