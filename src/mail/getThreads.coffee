{ CROSSMARK, CHECKMARK } = require "../constants"
{ logf, LOG }            = require "../logging"
{ forEach }              = require "../helpers"
{ formatWithOptions }    = require "util"

###
Returns a list of threads.
Here, a thread is a list of important message headers,
where the (n)th message is a reply to the (n-1)th message.
The headers returned are: from, to, date, and subject.
@param {string} query - The gmail query instructions.
@param {number} maxFetch - The maximum number of messages to query.
###
getThreads = (query, maxFetch = 10) ->
  gmail = @gmail
  
  listt = await gmail.users.threads.list { userId: "me", q: query, maxResults: maxFetch }
  unless listt.data.threads
    logf LOG.EMAIL, "{#ffee64-fg}#{CROSSMARK} No threads to query :/{/}"
    return []
  
  threads = await Promise.all listt.data.threads.map (thread) ->
    thred = await gmail.users.threads.get { userId: "me", id: thread.id }
    
    # Tell gmail that we've read the thread
    gmail.users.threads.modify {
      userId: "me"
      id: thread.id
      addLabelIds: []
      removeLabelIds: ["UNREAD"]
    }

    return thred.data.messages.map (message) ->
      headers = message.payload.headers.filter (header) ->
        /^(From|To|Date|Subject)$/.test header.name
      
      heds = {}
      headers.map (header) -> heds[header.name.toLowerCase()] = header.value
      return heds

  logf LOG.EMAIL, "{#32ff64-fg}{bold}#{CHECKMARK} #{threads.length}{/bold} Threads successfully read{/}"
  return threads

module.exports = getThreads
