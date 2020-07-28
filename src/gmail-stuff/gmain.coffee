fs = require 'fs'
gapis = require 'googleapis'
{ green, blue, bold } = require 'ansi-colors-ts'
forEach = require '../forEach'

###
Lists the messages in the user's account.
Return the messages to let them be used in
a useful way, like telling discord users that
their entered email address doesn't exist.
@param {gapis.gmail_v1.Gmail} gmail Gmail.
@param {gapis.google.auth.OAuth2} oAuth2Client An authorized OAuth2 client.
###
listMessages = (gmail, query) ->
  # mdstring = "# Lots of Messages about Unexisting Mails\n\n"
  listm = await gmail.users.messages.list { userId: "me", q: query, maxResults: 1 }
  if not listm.data.messages then return console.log "No messages to query :/"

  counter = 0
  something = await forEach listm.data.messages, (messageData) ->
    message = await gmail.users.messages.get { userId: "me", id: messageData.id }

    # Verifier that it is a message sending failure notification
    mailSys = message.data.payload.headers.find ((header) ->
      (/^From$/.test header.name) && (/^Mail/.test header.value))
    
    snippet = ""
    if mailSys
      # message.data.snippet is the readable content of the email
      snippet = message.data.snippet.replace /&#39;/g, "'"

      ###
      # All mdstrng stuff
      mdstring += "#{snippet}\n\n**#{mailSys.value}**\n"
      message.data.payload.headers.forEach ((header) ->
        valu = header.value.replace /\s\s+/g, "\n"
        if /^(From|To|Subject|Date)$/.test header.name
          mdstring += "- **#{header.name}**: #{valu}\n")
      mdstring += "\n"
      ###

      # To make the relevant message appear to be read in the mailbox
      gmail.users.messages.modify {
        userId: "me"
        id: messageData.id
        addLabelIds: []
        removeLabelIds: ["UNREAD"]
      }
    
    # mdstring += "***\n\n"
    counter++
    process.stdout.write "\x1b[2K\rMessages: #{bold (String counter)}"

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

  console.log something

  # console.log ("\n" + mdstring)
  console.log ("\n" + green (bold "Messages succesfully read"))

# Main function to do gmail stuff.
gmain = (oAuth2Client) ->
  console.log "Doing the gmain thing..."
  gmail = gapis.google.gmail { version: "v1", auth: oAuth2Client }
  await listMessages gmail, "is:unread label:existential-crisis"
  console.log "The gmain thing is finished"

module.exports = gmain