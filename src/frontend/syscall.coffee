YAML                                   = require "yaml"
RTFM                                   = require "./RTFM"
{ USER_TYPES, FOOTER }                 = require "../constants"
{ sendError, formatUser, formatGuild } = require "../logging"
{ getdbUser, getdbGuild, addRoletag }  = require "../db/dbhelpers"
{ User }                               = require "../db/initdb"
{ verifyUser }                         = require "../mail/verificationHandler"
{ decryptid }                          = require "../encryption"
{ Syscall, SacredArts }                = require "shisutemu-kooru"



syscallData =
  help:
    description: "Shows you how to use commands."
    args:
      with:
        position: "end"
        type: "word"
    exec: (args) -> (guild, msg) ->
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
  
  ping:
    description: "Ping."
    args: {}
    exec: (_) -> (guild, msg) ->
      embed = { description: "Ping." }
      m = await msg.channel.send { embed }
      embed.description = "Pong."
      await m.edit { embed }

  generate:
    description: "Generates RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (guild, msg) ->
      rtfm = await RTFM.fetch guild.client, guild.id
      
      unless rtfm.dbGuild.rtfm
        await msg.channel.send "Creating an RTFM category..."
        crtfm = await guild.channels.create "RTFM", {
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
    exec: ({ element }) -> (guild, msg) ->
      rtfm = await RTFM.fetch guild.client, guild.id
      
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
    exec: ({ element }) -> (guild, msg) ->
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
    exec: ({ element, shape }) -> (guild, msg) ->
      rtfm = await RTFM.fetch guild.client, guild.id
      
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
              .replace "{server}", guild.name
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
    exec: ({ id, shape }) -> (guild, msg) ->
      unless id
        await sendError msg.channel, "id is undefined"
        return
      member = await guild.members.fetch id
      dbUser = await getdbUser member.user
      unless dbUser
        await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return
      
      ## Putting a default shape, exploiting my own bug lmao
      unless shape then shape = ["student"]
      await msg.channel.send "`Giving user shape '#{shape.join "+"}'...`"
      addRoletag dbUser, sh for sh in shape
      await dbUser.update { roletags: dbUser.roletags }

      await msg.channel.send "`Verifying user #{member.user.tag}...`"
      await verifyUser dbUser, member, msg.author.tag
      await msg.channel.send "`User #{member.user.tag} verified.`"

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
    exec: ({ field, id, key, value }) -> (guild, msg) ->
      switch field
        when "user"
          member = await guild.members.fetch id
          dbUser = await getdbUser member.user, "silent"
          unless dbUser
            await sendError msg.channel, "User #{formatUser member.user} doesn't exist in the database :("
            return

          fields = ["email", "type", "code"]
          unless key in fields
            await sendError msg.channel, "Unknown or unauthorized user field `#{key}` :("
            return

          await msg.channel.send "Changing field `#{key}` of user #{formatUser member.user} to `#{value}`..."
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
    exec: ({ row, id, email }) -> (guild, msg) ->
      switch row
        when "user"
          if id
            try
              member = await guild.members.fetch id
            catch e
              await sendError msg.channel, "Unknown member `#{id}` :(\n\nError: ```\n#{e}```"
              return
            dbUser = await getdbUser member.user
            unless dbUser
              await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
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
              member = await guild.members.fetch id
            catch e
              await sendError msg.channel, "Unknown member `#{id}` :(\n\nError: ```\n#{e}```"
              return
          
          # Standing for Not So Sensible Data
          nssData = { dbUser.dataValues... }
          await msg.channel.send {
            embed:
              title: "#{member.user.tag}'s database row"
              description:
                """
                **#{member.user.tag}**'s database row in YAML form
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
          guild = await guild.client.guilds.fetch id
          unless guild
            await sendError msg.channel, "Unknown guild `#{id}` :("
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

module.exports = (guild, msg) ->
  evaluated = sacredArts.eval msg.content
  unless evaluated then return
  for { isError, error, result } in evaluated
    if isError
      errorMsg = if typeof error is "string" then error
      else "```yaml\n#{YAML.stringify error}\n```"
      await sendError msg.channel, errorMsg
      return
    await result(guild or msg.guild, msg)
