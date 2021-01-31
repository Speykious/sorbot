YAML                                   = require "yaml"
RTFM                                   = require "./RTFM"
{ USER_TYPES, FOOTER }                 = require "../constants"
{ sendError, formatUser, formatGuild } = require "../logging"
{ getdbUser, getdbGuild, addRoletag }  = require "../db/dbhelpers"
{ User }                               = require "../db/initdb"
{ verifyUser }                         = require "../mail/verificationHandler"
{ decryptid }                          = require "../encryption"
{ updateRoles }                        = require "../roles"
touchMember                            = require "../touchMember"
{ Syscall, SacredArts }                = require "shisutemu-kooru"

syscallData =
  help:
    description: "Shows you how to use commands."
    args:
      with:
        position: "end"
        type: "word"
    exec: (args) -> (msg) ->
      wth = args.with or "everything"
      switch wth
        when "everything"
          sdes = Object.entries syscallData
          await msg.channel.send sdes.map(
            ([name, { description }]) -> "`#{name}` ─ #{description}"
          ).join "\n"
        else
          { description, args } = syscallData[wth]
          await msg.channel.send "`#{wth}` ─ #{description}\n```yaml\n# Arguments\n#{YAML.stringify args}\n```"

  generate:
    description: "Generates RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (msg) ->
      try
        rtfm = await RTFM.fetch msg.guild.client, msg.guild.id
      catch e
        await sendError msg.channel, "Guild doesn't exist in the database :("
        return
      
      await msg.channel.send "`Generating pages...`"
      await rtfm.generatePageMsgs()
      await msg.channel.send "`All pages generated.`"

  yeet:
    description: "Yeets RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (msg) ->
      try
        rtfm = await RTFM.fetch msg.guild.client, msg.guild.id
      catch e
        await sendError msg.channel, "Guild doesn't exist in the database :("
        return
      
      await msg.channel.send "`Yeeting all pages...`"
      # Before yeeting the channels, we need to remove the RTFM instance's pagemsgs
      # from our data structures properly
      await for k, ch of rtfm.channelCache
        rtfm.pagemsgs = rtfm.pagemsgs.filter (pagemsg, i) ->
          if pagemsg.channel.id isnt ch.id
            return true
          else
            delete rtfm.pagemsgids[i]
            return false
        await ch.delete()
        delete rtfm.channelCache[k]
      rtfm.savePageMsgs()
      await msg.channel.send "`All pages from this guild have been yeeted.`"
  
  update:
    description: "Updates memory-internal RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (msg) ->
      await msg.channel.send "`Updating all memory-internal pages...`"
      RTFM.updatePageCache()
      await msg.channel.send "`All memory-internal pages updated.`"
  
  sync:
    description: "Syncs RTFM pages, specifically links."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
      shape:
        position: "end"
        type: "word"
        enum: ["link"]
    exec: ({ element, shape }) -> (msg) ->
      rtfm = await RTFM.fetch msg.guild.client, msg.guild.id
      
      await msg.channel.send "`Synchronizing all pages (shape: #{shape})...`"
      for pagemsg in rtfm.pagemsgs
        orig = pagemsg.embeds[0]
        RTFM.names.map (pagename, i) ->
          pageref = rtfm.pagemsgs[i]
          replaceStuff = (o, value) ->
            o[value] = o[value]
              .replace "{#{pagename}}",
                "https://discordapp.com/channels/#{
                  pageref.guild.id}/#{
                    pageref.channel.id}/#{
                      pageref.id}"
              .replace "{server}", msg.guild.name
              .replace "{description}", rtfm.dbGuild.description
          
          replaceStuff orig, "description"
          unless orig.fields then return
          orig.fields.map (_, i) -> replaceStuff orig.fields[i], "value"
        
        await pagemsg.edit null, orig

      await msg.channel.send "`Synchronized all pages.`"

  "verify-user":
    description: "Verifies a user."
    args:
      id:
        position: "start"
        type: "snowflake"
      shape:
        position: "end"
        type: "wordlist"
      email:
        position: "start"
        type: "word"
    exec: ({ id, shape, email }) -> (msg) ->
      unless id
        await sendError msg.channel, "id is undefined"
        return
      try
        user = await msg.client.users.fetch id
      catch e
        await sendError msg.channel, "Unknown user `#{id}` :("
        return
      dbUser = await getdbUser user, "silent"
      unless dbUser
        await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return
      
      ## Putting a default shape, exploiting my own bug lmao
      if shape then await msg.channel.send "`Giving user shape '#{shape.join "+"}'...`"
      else shape = []
      addRoletag dbUser, sh for sh in shape
      await dbUser.update { roletags: dbUser.roletags }
      if email
        await msg.channel.send "`Saving email '#{email}'...`"
        dbUser.email = email
        await dbUser.save()

      await msg.channel.send "`Verifying user #{user.tag}...`"
      await verifyUser dbUser, msg.client, user, msg.author.tag
      await msg.channel.send "`User #{user.tag} verified.`"
  
  "unverify-user":
    description: "Unverifies a user, and resets all its fields in the database."
    args:
      id:
        position: "start"
        type: "snowflake"
    exec: ({ id }) -> (msg) ->
      unless id
        await sendError msg.channel, "id is undefined"
        return
      try
        user = await msg.client.users.fetch id
      catch e
        await sendError msg.channel, "Unknown user `#{id}` :("
        return
      dbUser = await getdbUser user, "silent"
      unless dbUser
        await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return
      await msg.channel.send "`Unverifying user #{user.tag}...`"
      dbUser.roletags = ["unverified"]
      dbUser.reactor = null
      dbUser.email = null
      dbUser.code = null
      await dbUser.update { roletags: dbUser.roletags }
      await dbUser.save()
      await msg.channel.send "`Updating #{user.tag}'s roles everywhere...`"
      await updateRoles msg.client, dbUser
      await msg.channel.send "`User #{user.tag} unverified.`"
  
  "add-roleassoc":
    description: "Adds a role association in the current guild."
    args:
      roleid:
        position: "start"
        type: "snowflake"
      roletag:
        position: "start"
        type: "word"
    exec: ({ roleid, roletag }) -> (msg) ->
      unless roleid
        await sendError msg.channel, "roleid is undefined"
        return
      unless roletag
        await sendError msg.channel, "roletag is undefined"
        return
      dbGuild = await getdbGuild msg.guild, "silent"
      unless dbGuild
        await sendError msg.channel, "Guild #{formatGuild msg.guild} doesn't exist in our database :("
        return
      await msg.channel.send "`Adding association '#{roleid}:#{roletag}'...`"
      roleassocs = dbGuild.roleassocs
      roleassocs.push [roleid, roletag]
      await dbGuild.update { roleassocs }
      await msg.channel.send "`Association added.`"
  
  "remove-roleassoc":
    description: "Removes a role association from the current guild."
    args:
      roleid:
        position: "start"
        type: "snowflake"
      roletag:
        position: "start"
        type: "word"
    exec: ({ roleid, roletag }) -> (msg) ->
      unless roleid or roletag
        await sendError msg.channel, "Expected either roleid or roletag to be defined"
        return
      dbGuild = await getdbGuild msg.guild, "silent"
      unless dbGuild
        await sendError msg.channel, "Guild #{formatGuild guild} doesn't exist in our database :("
        return
      roleassocs = dbGuild.roleassocs
      if roleid
        await msg.channel.send "`Removing association with roleid '#{roleid}'...`"
        roleassocs = roleassocs.filter ([rid, _]) -> rid isnt roleid
      else if roletag
        await msg.channel.send "`Removing association with roletag '#{roletag}'...`"
        roleassocs = roleassocs.filter ([_, rtag]) -> rtag isnt roletag
      await dbGuild.update { roleassocs }
      await msg.channel.send "`Association removed.`"
  
  change:
    description: "Changes a field in the user database. Note: the field argument is just for command decoration :)"
    args:
      field:
        position: "end"
        type: "word"
        enum: ["user", "guild"]
      id:
        position: "start"
        type: "snowflake"
      key:
        position: "start"
        type: "word"
      value:
        position: "start"
        type: "string"
    exec: ({ field, id, key, value }) -> (msg) ->
      unless value then value = null
      switch field
        when "user"
          try
            user = await msg.client.users.fetch id
          catch e
            await sendError msg.channel, "Unknown user `#{id} :("
            return
          dbUser = await getdbUser user, "silent"
          unless dbUser
            await sendError msg.channel, "User #{formatUser user} doesn't exist in the database :("
            return

          fields = ["email", "type", "code"]
          unless key in fields
            await sendError msg.channel, "Unknown or unauthorized user field `#{key}` :("
            return

          await msg.channel.send "Changing field `#{key}` of user #{formatUser user} to `#{value}`..."
          dbUser[key] = value
          await dbUser.update { [key]: dbUser[key] }

        when "guild"
          unless id then id = msg.guild.id
          try
            guild = await msg.client.guilds.fetch id
          catch e
            await sendError msg.channel, "Unknown guild `#{id}` :("
            return
          dbGuild = await getdbGuild guild, "silent"
          unless dbGuild
            await sendError msg.channel, "Guild #{formatGuild guild} doesn't exist in the database :("
            return
          
          fields = ["rtfm", "description"]
          unless key in fields
            await sendError msg.channel, "Unknown of unauthorized guild field `#{key}` :("
            return

          await msg.channel.send "Changing field `#{key}` of guild #{formatGuild guild} to `#{value}`..."
          dbGuild[key] = value
          await dbGuild.save { fields: [key] }
          
      await msg.channel.send "`Field changed.`"
          
  get:
    description: "Fetches user/guild data from the database."
    args:
      row:
        position: "end"
        type: "word"
        enum: ["user", "guild"]
      id:
        position: "start"
        type: "snowflake"
      email:
        position: "start"
        type: "word"
    exec: ({ row, id, email }) -> (msg) ->
      switch row
        when "user"
          if id
            try
              user = await msg.client.users.fetch id
            catch e
              await sendError msg.channel, "Unknown user `#{id}` :(\n\nError: ```\n#{e}```"
              return
            dbUser = await getdbUser user, "silent"
            unless dbUser
              await sendError msg.channel, "User <@!#{user.id}> doesn't exist in the database :("
              return
          else if email
            try
              dbUser = await User.findOne {
                where: { email }
                rejectOnEmpty: yes
              }
            catch e
              await sendError msg.channel, "User not found for email `#{email}`."
              return
            id = decryptid dbUser.id
            try
              user = await msg.client.users.fetch id
            catch e
              await sendError msg.channel, "Unknown user `#{id}` :(\n\nError: ```\n#{e}```"
              return
          
          # Standing for Not So Sensible Data
          nssData = { dbUser.dataValues... }
          await msg.channel.send {
            embed:
              title: "#{user.tag}'s database row"
              description:
                """
                **#{user.tag}**'s database row in YAML form
                ```yaml
                #{YAML.stringify nssData}```
                """
              color: 0x34d9ff
              footer: FOOTER
          }
        when "guild"
          unless id then id = msg.guild.id
          try
            guild = await msg.client.guilds.fetch id
          catch e
            await sendError msg.channel, "Unknown guild `#{id}` :("
            return
          dbGuild = await getdbGuild guild, "silent"
          unless dbGuild
            await sendError msg.channel, "Guild #{formatGuild guild} doesn't exist in the database :("
            return
          
          # Standing for Not Sensible At All Data
          nsaaData = { dbGuild.dataValues... }
          await msg.channel.send {
            embed:
              title: "#{guild.name}'s database row"
              description:
                """
                **#{guild.name}**'s database row in YAML form
                ```yaml
                #{YAML.stringify nsaaData}```
                """
              color: 0x34d9ff
              footer: FOOTER
          }
        else
          await sendError msg.channel, "Expected row to be `user` or `guild`, got `#{field}`"
          return
  
  "add-users":
    description: "Adds all users of a guild to the database."
    args:
      id:
        position: "start"
        type: "snowflake"
    exec: ({ id }) -> (msg) ->
      unless id then id = msg.guild.id
      try
        guild = await msg.client.guilds.fetch id
      catch e
        await sendError msg.channel, "Unknown guild `#{id}` :("
        return
      dbGuild = await getdbGuild guild, "silent"
      unless dbGuild
        await sendError msg.channel, "Guild #{formatGuild guild} doesn't exist in the database :("
        return
      
      await msg.channel.send "`Fetching all members of guild '#{guild.name}' (#{guild.id})...`"
      try
        members = [(await guild.members.fetch()).values()...].filter (m) -> not m.user.bot
      catch e
        await sendError msg.channel "**UNEXPECTED ERROR** when fetching all the members of the guild! Please check the console log."
        return
      
      embed = {
        title: "SYSTEM-CALL"
        description: "Adding all users of guild #{formatGuild guild} to the database..."
        fields: [
          {
            name: "Members"
            value: 0
          }
        ]
        color: 0x34d9ff
      }
      embedmsg = await msg.channel.send { embed }
      
      for member in members
        await touchMember member
        embed.fields[0].value++
        await embedmsg.edit { embed }

      await msg.channel.send "`All users of guild '#{guild.name}' (#{guild.id}) have been added to the database.`"
  
  "add-user":
    description: "Adds a user to the database."
    args:
      id:
        position: "start"
        type: "snowflake"
    exec: ({ id }) -> (msg) ->
      await sendError msg.channel, "SYSTEM-CALL NOT IMPLEMENTED"

  "remove-user":
    description: "Removes a user from the database."
    args:
      id:
        position: "start"
        type: "snowflake"
    exec: ({ id }) -> (msg) ->
      await sendError msg.channel, "SYSTEM-CALL NOT IMPLEMENTED"
    

syscalls = Object.entries syscallData
          .map ([name, { args, exec }]) ->
            new Syscall { name, args }, exec

sacredArts = new SacredArts syscalls

module.exports = (msg) ->
  evaluated = sacredArts.eval msg.content
  unless evaluated then return
  for { isError, error, result } in evaluated
    if isError
      errorMsg = if typeof error is "string" then error
      else "```yaml\n#{YAML.stringify error}\n```"
      await sendError msg.channel, errorMsg
      return
    await result msg
