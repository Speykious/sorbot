{ bold, red, blue, underline }     = require "ansi-colors-ts"
getThreads                        = require "./getThreads"
verifyEmail                        = require "./verifyEmail"
{ CHECKMARK, CROSSMARK }           = require "../constants"
{ logf, LOG, formatCrisis }        = require "../logging"
{ relative, delay, readf, writef } = require "../helpers"
{ google }                         = require "googleapis"
readline                           = require "readline"
YAML                               = require "yaml"

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
      await @getNewToken tokenfile
  
  getThreads: (query, maxFetch = 10) ->
    (getThreads.bind @) query, maxFetch
  
  verifyEmail: (args...) ->
    (verifyEmail.bind @) args...
  
  ###
  Lists the unread existential crisis messages.
  Return the messages to let them be used in
  a useful way, like telling discord users that
  their entered email address doesn't exist.
  @param {number} maxFetch - The maximum number of messages to query.
  ###
  getUECThreads: (maxFetch = 10) ->
    logf LOG.EMAIL, "Reading Existential Crisis threads..."
    return @getThreads "is:unread label:existential-crisis", maxFetch

  ###
  Lists the unread sorbonne crisis messages.
  Return the messages to let them be used in
  a useful way, like telling discord users that
  their entered email address doesn't exist.
  @param {number} maxFetch - The maximum number of messages to query.
  ###
  getUSCThreads: (maxFetch = 10) ->
    logf LOG.EMAIL, "Reading Sorbonne Crisis threads..."
    return @getThreads "is:unread label:sorbonne-crisis", maxFetch


  ###
  Get and store new token after prompting for user authorization.
  @param {string} tokenfile - Path to the yaml file containing the gmail auth token.
  ###
  getNewToken: (tokenfile) ->
    authUrl = @oAuth2Client.generateAuthUrl {
      access_type: "offline"
      scope: @scopes
    }
    me = @
    console.log (blue "Authorize this app by visiting this url:"), authUrl
    rl = readline.createInterface {
      input: process.stdin,
      output: process.stdout,
    }

    return new Promise (resolve, reject) ->
      rl.question (blue "Enter the code from that page here: "), (code) ->
        rl.close()
        me.oAuth2Client.getToken code, (err, token) ->
          if err
            console.error "#{bold red CROSSMARK} Error retrieving access token:", err
            console.error "Please try again."
            return await me.getNewToken tokenfile

          me.oAuth2Client.setCredentials token

          # Store the token to disk for later program executions
          try
            writef tokenfile, (YAML.stringify token)
            console.log (bold "Token stored to"), (underline relative tokenfile)
            logf LOG.INIT, "{bold}Token stored to{/} {underline}#{relative tokenfile}{/}"
            resolve token
          catch err
            console.error err
            logf LOG.WTF, (formatCrisis "r/HolUp", err)
            reject err


module.exports = GMailer

