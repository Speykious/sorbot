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
  
  constructor: (@guild) ->
    # Caching the RTFM channels
    @channelCache = {}
    @pagemsgids = []
    @pagemsgs = []
    
    RTFM.RTFMs.push @

  # Gets the page object from .embed.yaml files
  @getPage: (pageName) ->
    unless pageName of @pageCache
      @pageCache[pageName] = YAML.parse readf mdir + pageName + ".embed.yaml"
      @pageCache[pageName].embed.footer = FOOTER
    return @pageCache[pageName]

  @clearPageCache: -> @pageCache = {}

  @updatePageCache: ->
    @clearPageCache()
    @names.map @getPage
  
  saveMenus = ->
    # These lines have to be changed.
    @pagemsgids = @pagemsgs.map (pagemsg) -> ({ ch: pagemsg.channel.id, msg: pagemsg.id })
    #writef "resources/menumsgs.yaml", YAML.stringify menumsgids
  


module.exports = RTFM
