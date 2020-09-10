{ User } = require "../db/initdb"
{ decryptid } = require "../encryption"

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
    @slowT = options.slowT or 300
    @fastT = options.fastT or 5
    
    @maxThreadsSlow = options.maxThreadsSlow or options.maxThreads or 20
    @maxThreadsFast = options.maxThreadsFast or options.maxThreads or 5
    
    @guild   = options.guild
    @gmailer = options.gmailer

    @embedUEC = options.embedUEC
    @embedUSC = options.embedUSC
    
    @_slowInt = undefined
    @_fastInt = undefined

  activate: ->
    @activateSlow()
    @activateFast()

  activateSlow: -> @_slowInt = setInterval @procU, @slowT
  activateFast: -> @_fastInt = setInterval @procC, @fastT

  deactivate: ->
    @deactivateSlow()
    @deactivateFast()

  deactivateSlow: -> clearInterval @_slowInt
  deactivateFast: -> clearInterval @_fastInt

  proc: (maxThreads) ->
    # Existential Crisis
    ethreads = await @gmailer.getUECThreads maxThreads
    for eth in ethreads
      # first message: what has been sent
      # second message: delivery failure notice
      console.log eth
      
      # Since emails are necessarily unique, that hardcode is safe
      euser = (await User.findAll {
        where:
          email: eth[0].to
      })[0]
      
      console.log "Embed to send:", (@embedUEC eth)
      console.log "User to send it to:", (decryptid euser.id)
    
    # Sorbonne Crisis
    sthreads = await @gmailer.getUSCThreads maxThreads
    console.log "(Read Sorbonne Crisis messages)"
  
  procU: -> @proc @maxThreadsSlow

module.exports = EmailCrisisHandler
