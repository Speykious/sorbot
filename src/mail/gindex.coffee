{ bold, red, green, blue, underline } = require "ansi-colors-ts"
{ google }                            = require "googleapis"
{ delay, readf, writef, CHECKMARK,
  CROSSMARK, templog, templogln }     = require "../utils"
readline                              = require "readline"
YAML                                  = require "yaml"
fs                                    = require "fs"

# If modifying these scopes, delete token.json.
SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"
          "https://www.googleapis.com/auth/gmail.modify"]
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "../token.yaml"

###
Create an OAuth2 client with the given credentials, and then execute the
given callback function.
@param {Object} credentials The authorization client credentials.
@param {function} callback The callback to call with the authorized client.
###
authorize = (credentials, callback) ->
  templog "Authorizing gmail access..."
  { client_secret, client_id, redirect_uris } = credentials.installed
  oAuth2Client = new google.auth.OAuth2 client_id, client_secret, redirect_uris[0]

  # Check if we have previously stored a token.
  try
    token = readf TOKEN_PATH
    oAuth2Client.setCredentials YAML.parse token
    templogln green CHECKMARK + " Authorized gmail access"
    callback oAuth2Client
  catch err
    getNewToken oAuth2Client, callback

###
Get and store new token after prompting for user authorization, and then
execute the given callback with the authorized OAuth2 client.
@param {google.auth.OAuth2} oAuth2Client The OAuth2 client to get token for.
@param {getEventsCallback} callback The callback for the authorized client.
###
getNewToken = (oAuth2Client, callback) ->
  authUrl = oAuth2Client.generateAuthUrl {
    access_type: "offline"
    scope: SCOPES
  }
  console.log (blue "Authorize this app by visiting this url:"), authUrl
  rl = readline.createInterface {
    input: process.stdin,
    output: process.stdout,
  }
  rl.question (blue "Enter the code from that page here: "), (code) ->
    rl.close()
    oAuth2Client.getToken code, (err, token) ->
      if err then return console.error (
        bold red CROSSMARK + " Error retrieving access token:"), err
      oAuth2Client.setCredentials token

      # Store the token to disk for later program executions
      try
        writef TOKEN_PATH, (YAML.stringify token)
        console.log (bold "Token stored to"), (underline relative TOKEN_PATH)
      catch err
        console.error err

      callback oAuth2Client


module.exports = {
  authorize
}