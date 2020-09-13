{ EmptyResultError }         = require "sequelize"
{ User }                     = require "../db/initdb"
{ decryptid }                = require "../encryption"
{ logf, LOG, colmat,
  formatCrisis, formatUser } = require "../logging"
handleVerification           = require "./verificationHandler"

###
The idea here:
Create an email reader with a request queue system.

We would have two different reading modes:
- the slow mode, where it would always periodically
  read all emails between relatively long time intervals;
- the fast request mode, where it would periodically
  read all emails between relatively short time intervals,
  but only if there are requests in the queue.

This class is for handling Email Crisis.
The job of a single instance is to read emails
according to the modes described above, and to then
notify the discord users according to the crisis read.

So, what it has to use:
- the gmailer which can read the emails and get the relevant information
- the main guild's members from where we can fetch every user to notify

Parameters to consider:
- The slow mode's and fast mode's period
- The error message embeds to send depending on the crisis
###
class EmailCrisisHandler
  # Options:
  # - slowT          {number}  - period for the slow read mode, in seconds
  # - fastT          {number}  - period for the fast read mode, in seconds
  # - maxThreads     {number}  - Maximum number of threads globally
  # - maxThreadsSlow {number}  - Maximum number of threads only for slow mode
  # - maxThreadsFast {number}  - Maximum number of threads only for fast mode
  # - guild          {Guild}   - The main discord guild to handle the crisis with
  # - gmailer        {GMailer} - The gmailer to read the email threads with
  # - embedUEC       {(thread) -> Embed} - The embed error report for Unread Existential Crisis
  # - embedUSC       {(thread) -> Embed} - The embed error report for Unread Sorbonne Crisis
  constructor: (options) ->
    @slowT = options.slowT or if process.env.LOCAL then 300 else 300
    @fastT = options.fastT or 5
    
    @maxThreadsSlow = options.maxThreadsSlow or options.maxThreads or 20
    @maxThreadsFast = options.maxThreadsFast or options.maxThreads or 5
    @requestFast = off
    
    @guild   = options.guild
    @gmailer = options.gmailer

    @embedUEC = options.embedUEC
    @embedUSC = options.embedUSC
    
    @_slowInt = undefined
    @_fastInt = undefined

  activate: ->
    @activateSlow()
    @activateFast()

  activateSlow: -> @_slowInt = setInterval (@procU.bind @), (@slowT * 1000)
  activateFast: -> @_fastInt = setInterval (@procC.bind @), (@fastT * 1000)

  deactivate: ->
    @deactivateSlow()
    @deactivateFast()

  deactivateSlow: -> clearInterval @_slowInt
  deactivateFast: -> clearInterval @_fastInt

  handleThread: (th, g_embed) ->
    # first message: what has been sent
    # second message: delivery failure notice
    { embed } = g_embed th
    
    try
      # Since emails are necessarily unique, that '[0]' hardcode is safe
      dbUser = (await User.findAll {
        where:
          email: th[0].to
        rejectOnEmpty: yes
      })[0]
      
    catch err
      unless err instanceof EmptyResultError
        logf LOG.WTF, "What the fuck just happened? <_<\n#{colmat err}"
        return
      
      logf LOG.DATABASE, (formatCrisis "Query", "User for email {#ff8032-fg}#{th[0].to}{/} has not been found")
      return
    
    member = await @guild.members.fetch decryptid dbUser.id
    logf LOG.MESSAGES, "Sending error report to user #{formatUser member.user} ({#32aa80-fg}'#{embed.title}'{/})"
    await member.user.send { embed }
  
  handleMV: (th) ->
    userEmail = th[0].from
    userEmail = userEmail.slice (userEmail.indexOf("<") + 1), (userEmail.length - 1)
    try
      # Since emails are necessarily unique, that '[0]' hardcode is safe
      dbUser = (await User.findAll {
        where:
          email: userEmail
        rejectOnEmpty: yes
      })[0]
      
    catch err
      unless err instanceof EmptyResultError
        logf LOG.WTF, "What the fuck just happened? <_<\n#{colmat err}"
      
      logf LOG.DATABASE, (formatCrisis "M-Query", "User for email {#ff8032-fg}#{userEmail}{/} has not been found")
      return
    
    member = await @guild.members.fetch decryptid dbUser.id
    unless th[0].subject.includes member.user.tag
      logf LOG.EMAIL, (formatCrisis "Email Subject", "User #{formatUser member.user} didn't include their discord tag in the subject of their email")
      # Log something in Discord here to notify the admins
      return
    logf LOG.MESSAGES, "'Manually' verifying user #{formatUser member.user}"
    # Noice little trick: do as if the user had entered the confirmation code :)
    handleVerification @gmailer, @, dbUser, member.user, dbUser.code
  
  proc: (maxThreads) ->
    # Existential Crisis
    ethreads = await @gmailer.getUECThreads maxThreads
    ethreads.map ((eth) -> @handleThread eth, @embedUEC).bind @
    
    # Sorbonne Crisis
    sthreads = await @gmailer.getUSCThreads maxThreads
    sthreads.map ((sth) -> @handleThread sth, @embedUSC).bind @

    # Manual Verification
    mthreads = await @gmailer.getUMVThreads maxThreads
    mthreads.map ((mth) -> @handleMV mth).bind @
  
  request: ->
    @requestFast = on
  
  procU: ->
    @proc @maxThreadsSlow
  procC: ->
    if @requestFast
      @proc @maxThreadsFast
      @requestFast = off
  
module.exports = EmailCrisisHandler
