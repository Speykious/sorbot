YAML                                   = require "yaml"
RTFM                                   = require "./RTFM"
{ USER_TYPES, FOOTER }                 = require "../constants"
{ sendError, formatUser, formatGuild } = require "../logging"
{ getdbUser, getdbGuild }              = require "../db/dbhelpers"
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

  generate:
    description: "Generates RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (guild, msg) ->
      rtfm = RTFM.RTFMs[guild.id]
      unless rtfm
        await sendError msg.channel, "Error: There is nothing to generate :("
        return
        
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
      rtfm = RTFM.RTFMs[guild.id]
      unless rtfm
        await sendError msg.channel, "Error: There is nothing to yeet :("
        return
      
      await msg.channel.send "`Yeeting all pages...`"
      # Before yeeting the channels, we need to remove the RTFM instance's pagemsgs
      # from our data structures properly
      await for k, ch of rtfm.channelCache
        rtfm.pagemsgs = rtfm.pagemsgs.filter (pagemsg, i) ->
          if pagemsg.channel.id isnt ch.id
            return true
          else
            delete pagemsgids[i]
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
      rtfm = RTFM.RTFMs[guild.id]
      unless rtfm
        await sendError msg.channel, "Error: There is nothing to synchronize :("
        return
      
      await msg.channel.send "`Synchronizing all pages (shape: #{shape})...`"
      rtfm.pagemsgs.map (menumsg) ->
        orig = menumsg.embeds[0]
        pagenames.map (pagename, i) ->
          pagemsg = rtfm.pagemsgs[i]
          replaceStuff = (o, value) ->
            o[value] = o[value]
              .replace "{#{pagename}}",
                "https://discordapp.com/channels/#{
                  pagemsg.guild.id}/#{
                    pagemsg.channel.id}/#{
                      pagemsg.id}"
              .replace "{server}", guild.name
          
          replaceStuff orig, "description"
          unless orig.fields then return
          orig.fields.map (_, i) -> replaceStuff orig.fields[i], "value"
        menumsg.edit { embed: orig }

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
        enum: ["student", "professor", "guest", "former"]
    exec: ({ id, shape }) -> (guild, msg) ->
      unless id
        await sendError msg.channel, "id is undefined"
        return
      member = await guild.members.fetch id
      dbUser = await getdbUser member.user
      unless dbUser
        await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return
      
      dbUser.type = 0
      ## Putting a default shape, exploiting my own bug lmao
      unless shape then shape = ["student"]
      await Promise.all shape.map (sh) ->
        sh = sh.toUpperCase()
        unless USER_TYPES[sh]
          await sendError msg.channel, "Unknown Shape `#{sh}` :("
          return
        await msg.channel.send "`Giving user shape '#{sh}'...`"
        dbUser.type |= USER_TYPES[sh]
      await dbUser.save()

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
          unless fields.includes key
            await sendError msg.channel, "Unknown or unauthorized user field `#{key}` :("
            return

          await msg.channel.send "`Changing field '#{key}' of user #{formatUser member.user} to '#{value}'...`"
          dbUser[key] = value
          await dbUser.save()

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
          unless fields.includes key
            await sendError msg.channel, "Unknown of unauthorized guild field `#{key}` :("
            return

          await msg.channel.send "`Changing field '#{key}' of guild #{formatGuild guild} to '#{value}'...`"
          dbUser[key] = value
          await dbUser.save()
          
      await msg.channel.send "`Field changed.`"
          
  
  "get-user":
    description: "Fetches user data from the user database."
    args:
      with:
        position: "start"
        type: "wordlist"
    exec: (args) -> (guild, msg) ->
      if args.with.length isnt 2
        await sendError msg.channel, "Expected 2 words, got #{args.with.length}"
        return
      field = args.with[0]
      switch field
        when "id"
          userId = args.with[1]
          unless /^\d{17,18}$/.test userId
            await sendError msg.channel, "Expected second word to be a snowflake, got '#{userId}'"
            return
          try
            member = await guild.members.fetch userId
          catch e
            await sendError msg.channel, "Unknown member `#{userId}` :(\n\nError: ```\n#{e}```"
            return
          dbUser = await getdbUser member.user
          unless dbUser
            await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
            return
        when "email"
          email = args.with[1]
          try
            dbUser = (await User.findAll {
              where: { email }
              rejectOnEmpty: yes
            })[0]
          catch e
            await sendError msg.channel, "User not found for email `#{email}`."
            return
          userId = decryptid dbUser.id
          try
            member = await guild.members.fetch userId
          catch e
            await sendError msg.channel, "Unknown member `#{userId}` :(\n\nError: ```\n#{e}```"
            return
        else
          await sendError msg.channel, "Expected first word to be 'id' or 'email', got '#{field}'"
          return

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
