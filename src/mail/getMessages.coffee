{ CROSSMARK, CHECKMARK } = require "../constants"
{ logf, LOG }            = require "../logging"
{ forEach }              = require "../helpers"


###
Lists and returns the messages in the user's account.
@param {number} maxFetch - The maximum number of messages to query.
@param {string} query - The gmail query instructions.
###
getMessages = (query, maxFetch = 10) ->
  listm = await @gmail.users.messages.list { userId: "me", q: query, maxResults: maxFetch }
  if not listm.data.messages
    logf LOG.MAIL, "{#ffff32-fg}{bold}#{CROSSMARK}{/bold} No messages to query :/{/}"
    return []

  counter = 0
  # overall: the variable that stores all the relevant data of all relevant messages
  overall = await forEach listm.data.messages, (messageData) ->
    message = await @gmail.users.messages.get { userId: "me", id: messageData.id }

    # message sending-failure notification identity-checker
    mailSys = message.data.payload.headers.find ((header) ->
      (header.name == "From") && (/^Mail/.test header.value))
    
    snippet = ""
    if mailSys
      # message.data.snippet is the readable content of the email
      snippet = message.data.snippet.replace /&#39;/g, "'"
      # To make the relevant message appear to be read in the mailbox
      @gmail.users.messages.modify {
        userId: "me"
        id: messageData.id
        addLabelIds: []
        removeLabelIds: ["UNREAD"]
      }
    
    if counter % 10 == 0
      logf LOG.MAIL, "Messages: {bold}#{String counter}{/}"

    counter++

    # To get the email address that failed
    failed_recipient = message.data.payload.headers.find((header) ->
      header.name == "X-Failed-Recipients").value
    # To get the date of when it failed
    failing_date = message.data.payload.headers.find((header) ->
      header.name == "Date").value
    
    return {
      content: snippet
      email: failed_recipient
      date: failing_date
    }
  
  logf LOG.MAIL, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Messages succesfully read{/}"

  return overall



module.exports = getMessages
