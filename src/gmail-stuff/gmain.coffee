fs = require 'fs'
gapis = require 'googleapis'
{ green, bold } = require 'ansi-colors-ts'
forEach = require '../forEach'

###
Lists the messages in the user"s account.
@param {gapis.gmail_v1.Gmail} gmail Gmail.
@param {gapis.google.auth.OAuth2} oAuth2Client An authorized OAuth2 client.
###
listMessages = (gmail, query) ->
  mdstring = "# Lots of Messages about Unexisting Mails\n\n"
  listm = await gmail.users.messages.list { userId: "me", q: query, maxResults: 500 }
  if not listm.data.messages then return

  counter = 0
  await forEach listm.data.messages, async messageData ->
    message = await gmail.users.messages.get { userId: "me", id: messageData.id }
    
    mailSys = message.data.payload.headers.find (
      (header) -> /^From$/.test header.name && /^Mail/.test header.value
    )
    
    if mailSys
      snippet = message.data.snippet
                .replace /&#39;/g, "\""
      mdstring += `#{snippet}\n\n**#{mailSys.value}**\n`

      message.data.payload.headers.forEach header ->
        valu = header.value.replace /\s\s+/g, "\n"
        if /^(From|To|Subject|Date)$/.test header.name
          mdstring += `- **#{header.name}**: #{valu}\n`

      mdstring += `\n`
    
    mdstring += `***\n\n`
    counter++
    process.stdout.write `\x1b[1000DMessages: #{bold(`#{counter}`)}`
  

  console.log mdstring
  fs.writeFileSync "./messages.md", mdstring, { encoding: "utf8" }
  console.log (green (bold "Messages succesfully saved"))


gmain = (oAuth2Client) ->
  gmail = gapis.google.gmail { version: "v1", auth: oAuth2Client }
  listMessages gmail, "label:Existential-Crisis"


module.exports = gmain