YAML                            = require "yaml"
{ readf, writef }               = require "../helpers"
{ SERVERS, USER_TYPES, FOOTER } = require "../constants"
{ sendError }                   = require "../logging"
{ getdbUser, getdbGuild }       = require "../db/dbhelpers"
{ User }                        = require "../db/initdb"
{ verifyUser }                  = require "../mail/verificationHandler"
{ getPage, clearPageCache }     = require "./pageHandler"
{ decryptid }                   = require "../encryption"
{ Syscall, SacredArts }         = require "shisutemu-kooru"



# Class for an RTFM page.
class RTFM
  # Directory where the page files are stored
  @dir: "resources/pages/"
  # Names of the pages we care about
  @names: [
    "accueil"
    "page0_aas"
    "page1_jse"
    "page2_jspoec"
    "page3_jsumdpdsu"
    "page4_jsupe"
    "page5_jnrpdm"
    "page6_rgpd"
    "page6.1_pencd"
    "page6.2_qeidls"
    "page6.3_crmd"
    "page7_gud"
    "page8_qsn"
    "page9_qqs"
  ]
  # Cache of page objects
  @pageCache: {}
  # All RTFM instances
  @RTFMs: {}

  constructor: (@guild) ->
    # Caching the RTFM channels
    @channelCache = {}
    @pagemsgids = []
    @pagemsgs = []
    @dbGuild = getdbGuild @guild
    unless @dbGuild
      throw new Error "Trying to construct an RTFM without the guild being in the database"
    
    RTFM.RTFMs[@guild.id] = @



  # Gets the page object from .embed.yaml files
  @getPage: (pageName) ->
    unless pageName of RTFM.pageCache
      RTFM.pageCache[pageName] = YAML.parse readf "#{RTFM.dir}#{pageName}.embed.yaml"
      RTFM.pageCache[pageName].embed.footer = FOOTER
    return RTFM.pageCache[pageName]



  # Clears the page cache, aga
  @clearPageCache: -> RTFM.pageCache = {}



  # Updates the page cache: clear, then get each page by reading the YAML files
  @updatePageCache: ->
    RTFM.clearPageCache()
    RTFM.names.map RTFM.getPage
  
  

  # Loads the IDs of the page messages and channels from the database
  loadPageMsgs: ->
    @pagemsgids = @dbGuild.rtfms.split "\n"
      .map (line) -> line.split "|"
      .map ([chid, msgids]) ->
        msgids.split " "
        .map (msgid) -> ({ chid, msgid })


  
  # Saves the IDs of the page messages and channels into the database
  savePageMsgs: ->
    rtfms = {}
    for pagemsg in @pagemsgs
      chid = pagemsg.channel.id
      unless rtfms[chid] then rtfms[chid] = []
      rtfms[chid].push pagemsg.id

    @dbGuild.rtfms = Object.entries rtfms
      .map ([chid, msgids]) -> "#{chid}|#{msgids.join " "}"
      .join "\n"
    
    console.log @dbGuild.rtfms
    @dbGuild.save()
  
  
  
  # Generates the embed pages in their corresponding threads
  generatePageMsgs: ->
    guild = @guild
    categoryId = @dbGuild.rtfm
    channelCache = @channelCache
    pages = Object.values RTFM.pageCache
    pagemsgids = @pagemsgids
    pagemsgs = @pagemsgs

    channeler = (pages, i = 0) ->
      if i >= pages.length then return

      page = pages[i]
      if pagemsgids[i]
        unless channelCache[page.thread.name]
          channelCache[page.thread.name] = guild.channels.resolve pagemsgids[i].chid
        unless pagemsgs[i]
          pagemsgs[i] = await channelCache[page.thread.name].messages.fetch pagemsgids[i].msgid
      
      unless channelCache[page.thread.name]
        channelCache[page.thread.name] =
          await guild.channels.create page.thread.name, {
            topic: page.thread.topic
            parent: categoryId
          }
      
      # And here we witness the weirdest condition logic
      # ever seen in the entire history of programming
      # in its natural habitat
      unless pagemsgs[i]
        pagemsgs[i] = await channelCache[page.thread.name].send { embed: page.embed }
      else if pagemsgs[i].client.user.id is pagemsgs[i].author.id
        await pagemsgs[i].edit { embed: page.embed }
      else
        await pagemsgs[i].delete()
        pagemsgs[i] = await channelCache[page.thread.name].send { embed: page.embed }

      channeler pages, i + 1

    await channeler pages
    @savePageMsgs()


module.exports = RTFM
