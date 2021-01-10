YAML                            = require "yaml"
{ readf, writef }               = require "../helpers"
{ SERVERS, USER_TYPES, FOOTER } = require "../constants"
{ sendError }                   = require "../logging"
{ getdbUser, getdbGuild }       = require "../db/dbhelpers"
{ User }                        = require "../db/initdb"
{ verifyUser }                  = require "../mail/verificationHandler"
{ getPage, clearPageCache }     = require "./page-handler"
{ decryptid }                   = require "../encryption"
{ Syscall, SacredArts }         = require "shisutemu-kooru"


updateMenus = ->
  clearPageCache()
  menus = pagenames.map getPage

saveMenus = ->
  menumsgids = menumsgs.map (menumsg) -> ({ ch: menumsg.channel.id, msg: menumsg.id })
  writef "resources/menumsgs.yaml", YAML.stringify menumsgids

# Generates the embed pages in their corresponding threads
generatePages = (menus, guild, parentId) ->
  channeler = (menus, i = 0) ->
    if i >= menus.length then return

    menu = menus[i]
    if menumsgids[i]
      unless channelCache[menu.thread.name]
        channelCache[menu.thread.name] = guild.channels.resolve menumsgids[i].ch
      unless menumsgs[i]
        menumsgs[i] = await channelCache[menu.thread.name].messages.fetch menumsgids[i].msg
    
    unless channelCache[menu.thread.name]
      channelCache[menu.thread.name] =
        await guild.channels.create menu.thread.name, {
          topic: menu.thread.topic
          parent: parentId
        }
    
    # And here we witness the weirdest condition logic
    # ever seen in the entire history of programming
    # in its natural habitat
    unless menumsgs[i]
      menumsgs[i] = await channelCache[menu.thread.name].send { embed: menu.embed }
    else if menumsgs[i].client.user.id is menumsgs[i].author.id
      await menumsgs[i].edit { embed: menu.embed }
    else
      await menumsgs[i].delete()
      menumsgs[i] = await channelCache[menu.thread.name].send { embed: menu.embed }

    channeler menus, i + 1

  await channeler menus
  saveMenus()

updateMenus()

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
          await msg.channel.send sdes.map(([name, { description }]) -> "`#{name}` ─ #{description}").join("\n")
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
      dbGuild = await getdbGuild guild, "silent"
      unless dbGuild
        await sendError msg.channel, "Guild is not in the database *(nani)*"
        return
      unless dbGuild.rtfm
        await sendError msg.channel, "Guild's metadata doesn't include an RTFM category"
        return
      await msg.channel.send "`Generating pages...`"
      await generatePages menus, guild, dbGuild.rtfm
      await msg.channel.send "`All pages generated.`"

  yeet:
    description: "Yeets RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (guild, msg) ->
      await msg.channel.send "`Yeeting all pages...`"
      # Before yeeting the channels, we need to remove our menumsgs
      # from our data structures properly
      await for k, ch of channelCache
        menumsgs = menumsgs.filter (menumsg, i) ->
          if menumsg.channel.id isnt ch.id
            return true
          else
            delete menumsgids[i]
            return false
        await ch.delete()
        delete channelCache[k]
      saveMenus()
      await msg.channel.send "`All pages yeeted.`"
  
  update:
    description: "Updates memory-internal RTFM pages."
    args:
      element:
        position: "end"
        type: "word"
        enum: ["pages", "all-pages", "page", "all-page"]
    exec: ({ element }) -> (guild, msg) ->
      await msg.channel.send "`Updating all memory-internal pages...`"
      updateMenus()
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
      await msg.channel.send "`Synchronizing all pages (shape: #{shape})...`"
      menumsgs.map (menumsg) ->
        orig = menumsg.embeds[0]
        pagenames.map (pagename, i) ->
          replaceLink = (o, value) ->
            o[value] = o[value].replace "{#{pagename}}",
              "https://discordapp.com/channels/#{
                menumsgs[i].guild.id}/#{
                  menumsgs[i].channel.id}/#{
                    menumsgs[i].id}"
          
          replaceLink orig, "description"
          unless orig.fields then return
          orig.fields.map (_, i) -> replaceLink orig.fields[i], "value"
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
        enum: ["user"]
      id:
        position: "start"
        type: "snowflake"
      key:
        position: "start"
        type: "word"
      value:
        position: "start"
        type: "word"
    exec: ({ id, key, value }) -> (guild, msg) ->
      member = await guild.members.fetch userId
      dbUser = await getdbUser member.user
      unless dbUser
        await sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return

      fields = ["email", "type", "code"]
      ni = fields.indexOf name
      if ni is -1
        await sendError msg.channel, "Unknown or unauthorized user field `#{name}` :("
        return
      name = fields[ni]

      await msg.channel.send "`Changing field '#{name}' of user '#{member.user.tag}' to '#{value}'...`"
      dbUser[name] = value
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
    await result guild, msg
