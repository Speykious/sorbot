YAML                                   = require "yaml"
RTFM                                   = require "./RTFM"
{ USER_TYPES, FOOTER }                 = require "../constants"
{ sendError, formatUser, formatGuild } = require "../logging"
{ getdbUser, getdbGuild, addRoletag }  = require "../db/dbhelpers"
{ User }                               = require "../db/initdb"
{ verifyUser }                         = require "../mail/verificationHandler"
{ decryptid }                          = require "../encryption"
{ updateRoles }                        = require "../roles"
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
      rtfm = await RTFM.fetch msg.guild.client, msg.guild.id
      
      unless rtfm.dbGuild.rtfm
        await msg.channel.send "Creating an RTFM category..."
        crtfm = await msg.guild.channels.create "RTFM", {
          type: "category"
          topic: "READ THE FUCKING MANUAL"
          reason: "Generating RTFM pages"
          position: 0
        }
        rtfm.dbGuild.rtfm = crtfm.id
        await rtfm.dbGuild.save()
      
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
      rtfm = await RTFM.fetch msg.guild.client, msg.guild.id
      
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
      dbUser = await getdbUser user
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
      dbUser = await getdbUser user
      unless dbUser
        await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return
      await msg.channel.send "`Unverifying user #{user.tag}...`"
      dbUser.roletags = ["unverified"]
      dbUser.reactor = null
      dbUser.email = null
      dbUser.code = null
      dbUser.update { roletags: dbUser.roletags }
      await dbUser.save()
      await msg.channel.send "`Updating #{user.tag}'s roles everywhere...`"
      await updateRoles msg.client, dbUser
      await msg.channel.send "`User #{user.tag} unverified.`"

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
          if id
            guild = RTFM.RTFMs[id].guild
            unless guild
              await sendError msg.channel, "Guild with ID `#{id}` not found"
              return
          dbGuild = await getdbGuild guild, "silent"
          unless dbGuild
            await sendError msg.channel, "Guild #{formatGuild guild} doesn't exist in our database :("
            return
          
          fields = [
            "rtfm", "description"
            "unverified", "member", "professor"
            "guest", "former"
          ]
          unless key in fields
            await sendError msg.channel, "Unknown of unauthorized guild field `#{key}` :("
            return

          await msg.channel.send "Changing field `#{key}` of guild #{formatGuild guild} to `#{value}`..."
          dbGuild[key] = value
          await dbGuild.save { fields: [key] }
          
      await msg.channel.send "`Field changed.`"
          
  get:
    description: "Fetches user data from the user database."
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
            dbUser = await getdbUser user
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
              await sendError msg.channel, "Unknown member `#{id}` :(\n\nError: ```\n#{e}```"
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
          unless id
            await sendError msg.channel, "Guild ID is undefined"
            return
          try
            guild = await msg.client.guilds.fetch id
          catch e
            await sendError msg.channel, "Unknown guild `#{id}` :("
            return
          dbGuild = await getdbGuild guild
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
