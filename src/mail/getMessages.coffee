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
    logf LOG.EMAIL, "{#ffff32-fg}{bold}#{CROSSMARK}{/bold} No messages to query :/{/}"
    return []

  counter = 0
  gmail = @gmail
  # overall: the variable that stores all the relevant data of all relevant messages
  overall = await forEach listm.data.messages, (messageData) ->
    message = await gmail.users.messages.get { userId: "me", id: messageData.id }
    
    # logf LOG.EMAIL, message.data.payload.headers # <- temp log here
    # message sending-failure notification identity-checker
    mailSys = message.data.payload.headers.find ((header) ->
      (header.name == "From") && (/^Mail/.test header.value))
    
    snippet = ""
    if mailSys
      # message.data.snippet is the readable content of the email
      snippet = message.data.snippet.replace /&#39;/g, "'"
      # To make the relevant message appear to be read in the mailbox
      gmail.users.messages.modify {
        userId: "me"
        id: messageData.id
        addLabelIds: []
        removeLabelIds: ["UNREAD"]
      }
    
    if counter % 10 == 0
      logf LOG.EMAIL, "Messages: {bold}#{String counter}{/}"

    counter++

    getHeader = (hn) ->
      message.data.payload.headers.find((header) ->
        header.name is hn).value

    failed_recipient = getHeader "X-Failed-Recipients" # To get the email address that failed
    failing_date     = getHeader "Date"                # To get the date of when it failed
    subject          = getHeader "Subject"             # To get the subject of the email
    
    return {
      content: snippet
      email: failed_recipient
      date: failing_date
      subject
    }
  
  logf LOG.EMAIL, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Messages succesfully read{/}"

  return overall



module.exports = getMessages
