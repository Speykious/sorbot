fs                   = require "fs"
{ relative, delay }  = require "../utils"
readline             = require "readline"
{ google }           = require "googleapis"
{ bold, red, green } = require "ansi-colors-ts"

# If modifying these scopes, delete token.json.
SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]
# The file token.json stores the user"s access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = relative "../token.json"

###
Create an OAuth2 client with the given credentials, and then execute the
given callback function.
@param {Object} credentials The authorization client credentials.
@param {function} callback The callback to call with the authorized client.
###
authorize = (credentials, callback) ->
  { client_secret, client_id, redirect_uris } = credentials.installed
  oAuth2Client = new google.auth.OAuth2 client_id, client_secret, redirect_uris[0]

  # Check if we have previously stored a token.
  fs.readFile TOKEN_PATH, (err, token) ->
    if err then return getNewToken oAuth2Client, callback
    oAuth2Client.setCredentials (JSON.parse token)
    callback oAuth2Client

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
  console.log (green "Authorize this app by visiting this url:"), authUrl
  rl = readline.createInterface {
    input: process.stdin,
    output: process.stdout,
  }
  rl.question (green "Enter the code from that page here: "), (code) ->
    rl.close()
    oAuth2Client.getToken code, (err, token) ->
      if err then return console.error (bold (red "Error retrieving access token")), err
      oAuth2Client.setCredentials token
      # Store the token to disk for later program executions
      fs.writeFile TOKEN_PATH, (JSON.stringify token), (err) ->
        if err then return console.error err
        console.log (bold (green "Token stored to")), TOKEN_PATH
      
      callback oAuth2Client


module.exports = {
  authorize
}