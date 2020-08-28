{ Sequelize, DataTypes } = require "sequelize"
{ CROSSMARK, CHECKMARK } = require "../constants"
{ logf, LOG, formatCrisis,
  truncateStr }          = require "../logging"
{ format }               = require "util"

genUser = require "./models/User"
genFederatedMetadata = require "./models/FederatedMetadata"

pe = process.env

logf LOG.DATABASE, "{#ff8032-fg}Creating{/} connection..."

uri = if pe.LOCAL
then "postgres://#{pe.DB_USER}:#{pe.DB_PASS}@localhost:5432/sorbot-dev"
else "postgres://sorbot:#{pe.DB_PASS}@localhost:5432/sorbot"
connection = new Sequelize uri, {
  logging: (msgs...) -> logf LOG.DATABASE, (msgs.map (msg) ->
    truncateStr format msg
  )...
}

logf LOG.DATABASE, "{#ff8032-fg}Defining{/} models..."
User              = genUser              connection
FederatedMetadata = genFederatedMetadata connection

logf LOG.DATABASE, "{#ff8032-fg}Syncing{/} connection..."
connection.sync()
  .then logf LOG.DATABASE, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Dank database connection established{/}"
  .catch (err) -> logf LOG.DATABASE, "{#ff6432-fg}{bold}#{CROSSMARK}{/bold} Haha yesn't:{/} #{err}"


module.exports = {
  connection
  User
  FederatedMetadata
}
