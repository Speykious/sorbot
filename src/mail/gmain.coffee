{ green, blue, bold, dim, yellow } = require 'ansi-colors-ts'
gapis                              = require 'googleapis'
{ forEach, CHECKMARK, CROSSMARK }  = require '../utils'
{ logf, LOG, formatCrisis }        = require '../logging'
fs                                 = require 'fs'

###
Lists the messages in the user's account.
Return the messages to let them be used in
a useful way, like telling discord users that
their entered email address doesn't exist.
@param {gapis.gmail_v1.Gmail} gmail Gmail.
@param {gapis.google.auth.OAuth2} oAuth2Client An authorized OAuth2 client.
###
getUnreadMessages = (maxFetch = 10) -> (gmail, query) ->
  listm = await gmail.users.messages.list { userId: "me", q: query, maxResults: maxFetch }
  if not listm.data.messages
  then return logf LOG.MAIL, "{#ffff32-fg}{bold}#{CROSSMARK}{/bold} No messages to query :/{/}"

  counter = 0
  # overall: the variable that stores all the relevant data of all relevant messages
  overall = await forEach listm.data.messages, (messageData) ->
    message = await gmail.users.messages.get { userId: "me", id: messageData.id }

    # message sending-failure notification identity-checker
    mailSys = message.data.payload.headers.find ((header) ->
      (/^From$/.test header.name) && (/^Mail/.test header.value))
    
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
    
    counter++

    if counter == 1 or counter % 10 == 0
    then logf LOG.MAIL, "Messages: {bold}#{String counter}{/}"

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

# Main function to do gmail stuff.
gmain = (oAuth2Client) ->
  logf LOG.MAIL, "Reading Existential Crisis messages..."
  gmail = gapis.google.gmail { version: "v1", auth: oAuth2Client }
  # The curried arg of getUnreadMessages is the number of unread
  # messages to fetch. It will likely be changed in the future.
  await (getUnreadMessages 20) gmail, "is:unread label:existential-crisis"

module.exports = gmain
