{ bold, red, blue, underline } = require "ansi-colors-ts"
{ google }                     = require "googleapis"
{ delay, readf, writef, relative,
  CHECKMARK, CROSSMARK,
  logf, LOG, formatCrisis }    = require "../utilog"
readline                       = require "readline"
YAML                           = require "yaml"

class GMailer
  ###
  Construct a GMailer object.
  @param {GMailScopes[]} scopes - The googleapis auth gmail scopes for the oAuth2Client.
  @param {string} credfile - Path to the yaml file containing the gmail credentials.

  PS: type GMailScopes = "labels" | "send" | "readonly" | "compose" | "insert"
                       | "modify" | "metadata" | "settings.basic" | "settings.sharing"
  ###
  constructor: (scopes, credfile) ->
    @scopes = scopes.map (scope) -> "https://www.googleapis.com/auth/gmail.#{scope}"
    @authorized = no # Tells us if the GMailer has been authorized to interact with gmail

    try # Load client secrets from a local file.
      credentials = YAML.parse readf credfile
      { client_secret, client_id, redirect_uris } = credentials.installed
      @oAuth2Client = new google.auth.OAuth2 client_id, client_secret, redirect_uris[0]
      @gmail = google.gmail { version: "v1", auth: @oAuth2Client }
    catch err
      logf LOG.INIT, (formatCrisis "Loading", "({underline}credentials.yaml{/underline}) #{err}")
  
  ###
  Create an OAuth2 client with the given credentials.
  @param {string} tokenfile - Path to the yaml file containing the gmail auth token.
  ###
  authorize: (tokenfile) ->
    logf LOG.INIT, "Authorizing gmail access..."
    
    try # Check if we have previously stored a token.
      @oAuth2Client.setCredentials YAML.parse readf tokenfile
      logf LOG.INIT, "{#32ff64-fg}#{CHECKMARK} Authorized gmail access{/}"
      @authorized = yes # I like boolean homonyms <w<
    catch err
      logf LOG.INIT, (formatCrisis "Credentials",
        "The Gmail token is missing! You need to go to {bold}SorBOT's stdin{/bold} to create a new one.")
      @getNewToken tokenfile

  ###
  Lists the unread existential crisis messages.
  Return the messages to let them be used in
  a useful way, like telling discord users that
  their entered email address doesn't exist.
  @param {number} maxFetch - The maximum number of messages to query.
  @param {string} query - The gmail query instructions.
  ###
  getUECMessages: (maxFetch = 10) ->
    logf LOG.MAIL, "Reading Existential Crisis messages..."
    return @getMessages maxFetch, "is:unread label:existential-crisis"

  ###
  Get and store new token after prompting for user authorization.
  @param {string} tokenfile - Path to the yaml file containing the gmail auth token.
  ###
  getNewToken = (tokenfile) ->
    authUrl = @oAuth2Client.generateAuthUrl {
      access_type: "offline"
      scope: @scopes
    }
    console.log (blue "Authorize this app by visiting this url:"), authUrl
    rl = readline.createInterface {
      input: process.stdin,
      output: process.stdout,
    }
    rl.question (blue "Enter the code from that page here: "), (code) ->
      rl.close()
      @oAuth2Client.getToken code, (err, token) ->
        if err
          console.error "#{bold red CROSSMARK} Error retrieving access token:", err
          console.error "Please try again."
          return @getNewToken tokenfile

        @oAuth2Client.setCredentials token

        # Store the token to disk for later program executions
        try
          writef tokenfile, (YAML.stringify token)
          console.log (bold "Token stored to"), (underline relative tokenfile)
          logf LOG.INIT, "{bold}Token stored to{/} {underline}#{relative tokenfile}{/}"
        catch err
          console.error err
          logf LOG.WTF, (formatCrisis "r/HolUp", err)

  ###
  Lists and returns the messages in the user's account.
  @param {number} maxFetch - The maximum number of messages to query.
  @param {string} query - The gmail query instructions.
  ###
  getMessages = (maxFetch = 10, query) ->
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



module.exports = {
  GMailer
}
