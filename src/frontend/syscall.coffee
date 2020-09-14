YAML                    = require "yaml"
{ readf, writef }       = require "../helpers"
{ SERVERS, USER_TYPES } = require "../constants"
{ sendError }           = require "../logging"
{ getdbUser }           = require "../db/dbhelpers"
{ User }                = require "../db/initdb"
{ verifyUser }          = require "../mail/verificationHandler"

mdir = "resources/pages/"
pagenames = [
  "accueil"
  "page0_aas"
  "page1_jse"
  "page2_jspoec"
  "page3_jsumdpdsu"
  "page4_jsupe"
  "page5_jnrpdm"
  "page6_rgpd"
  "page7_gud"
  "page8_qsn"
  "page9_qqs"
]
channelCache = {}
menus = []
menumsgs = []
menumsgids = YAML.parse readf "resources/menumsgs.yaml"
unless menumsgids then menumsgids = []

updateMenus = ->
  menus = pagenames.map (pagename) -> YAML.parse readf mdir + pagename + ".embed.yaml"

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
        channelCache[menu.thread.name] = guild.channels.cache.get menumsgids[i].ch
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

# SAO Alicization SYSTEM CALLS for menu handling
syscall = (guild, msg, cmd) ->
  unless cmd then cmd = msg.content
  if /^(SYSTEM CALL|SC):\n/.test cmd
    cmds = cmd.split(/\n+/).slice 1
           .map (cmd) -> "SC: #{cmd}"
    syscalls = (i = 0) ->
      if i >= cmds.length then return
      await syscall guild, msg, cmds[i]
      return syscalls i + 1
    return syscalls()
  
  unless cmd.startsWith "SYSTEM CALL: "
    unless /^SC:\s/.test cmd then return
    else cmd = cmd.slice "SC: ".length
  else cmd = cmd.slice "SYSTEM CALL: ".length


  switch cmd

    when "GENERATE ALL PAGE ELEMENT"
      await msg.channel.send "`Generating pages...`"
      await generatePages menus, guild, "751750178058534912"
      await msg.channel.send "`All pages generated.`"

    when "YEET ALL PAGE ELEMENT"
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

    when "UPDATE ALL PAGE ELEMENT"
      await msg.channel.send "`Updating all memory-internal pages...`"
      updateMenus()
      await msg.channel.send "`All memory-internal pages updated.`"

    when "SYNC ALL PAGE ELEMENT, LINK SHAPE"
      await msg.channel.send "`Synchronizing all pages (shape: link)...`"
      menumsgs.map (menumsg) ->
        orig = menumsg.embeds[0]
        pagenames.map (pagename, i) ->
          orig.description = orig.description.replace "{#{pagename}}",
            "https://discordapp.com/channels/#{
              menumsgs[i].guild.id}/#{
              menumsgs[i].channel.id}/#{
              menumsgs[i].id}"
        menumsg.edit { embed: orig }
      await msg.channel.send "`Synchronized all pages.`"
    
    else
      unless cmd.startsWith "VERIFY USER, ID " then return
      
      cmd = cmd.slice "VERIFY USER, ID ".length
      unless /^\d{18}/.test cmd then return
      userId = cmd.slice 0, 18
      cmd = cmd.slice 18
      member = await guild.members.fetch userId
      dbUser = await getdbUser member.user
      unless dbUser
        sendError msg.channel, "User <@!#{member.user.id}> doesn't exist in the database :("
        return
      
      if /^,\s+(\d+\s+)+SHAPE/.test cmd then
        shapes = cmd.split(/\s+/).slice 1
        shapes.slice 1, shapes.length - 1 # we don't want 'SHAPE' or ',' in here
        shapes.map (shape) ->
          unless USER_TYPES[shape]
            sendError msg.channel, "Unknown Shape `#{shape}` :("
            return
          dbUser.userType |= USER_TYPES[shape]
        dbUser.save()
      
      await verifyUser dbUser, member, verifier, msg.author.tag

module.exports = syscall
