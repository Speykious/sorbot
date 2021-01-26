{ Sequelize, DataTypes } = require "sequelize"
{ CROSSMARK, CHECKMARK } = require "../constants"
{ LOG, formatCrisis,
  truncateStr }          = require "../logging"
loading                  = require "../loading"
{ format }               = require "util"

genUser = require "./models/User"
genFederatedMetadata = require "./models/FederatedMetadata"

pe = process.env

loading.step "Initializing database - Creating connection..."
uri = if pe.LOCAL
then "postgres://#{pe.DB_USER}:#{pe.DB_PASS}@localhost:5432/sorbot-dev"
else "postgres://sorbot:#{pe.DB_PASS}@localhost:5432/sorbot"
connection = new Sequelize uri, {
  logging: -> # literally yeet loggings into oblivion
}

loading.step "Initializing database - Defining models..."
User              = genUser              connection
FederatedMetadata = genFederatedMetadata connection

loading.step "Initializing database - Syncing connection..."
connection.sync()
  .then -> loading.step "Dank database connection established"
  .catch (err) ->
    loading.stopDisplaying()
    console.log "\x1b[1m\x1b[31m#{CROSSMARK}\x1b[22m Haha yesn't:\x1b[0m #{err}"
    process.exit 1


module.exports = {
  connection
  User
  FederatedMetadata
}
