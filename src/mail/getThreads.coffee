{ CROSSMARK, CHECKMARK } = require "../constants"
{ LOG }            = require "../logging"
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
  unless listt.data.threads then return []
  
  threads = await Promise.all listt.data.threads.map (thread) ->
    thred = await gmail.users.threads.get { userId: "me", id: thread.id }
    
    manver = /label:manual-verification/.test query
    # Tell gmail that we've read the thread
    gmail.users.threads.modify {
      userId: "me"
      id: thread.id
      addLabelIds:    if manver then ["manual-verification/handled"]   else []
      removeLabelIds: if manver then ["manual-verification", "UNREAD"] else ["UNREAD"]
    }

    return thred.data.messages.map (message) ->
      headers = message.payload.headers.filter (header) ->
        /^(From|To|Date|Subject)$/.test header.name
      
      heds = {}
      headers.map (header) -> heds[header.name.toLowerCase()] = header.value
      return heds

  return threads

module.exports = getThreads
