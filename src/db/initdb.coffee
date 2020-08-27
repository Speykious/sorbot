{ Sequelize, DataTypes }    = require "sequelize"
{ CROSSMARK, CHECKMARK }    = require "../constants"
{ logf, LOG, formatCrisis } = require "../logging"
{ format }                  = require "util"

User = require "./models/User"
FederatedMetadata = require "./models/FederatedMetadata"

pe = process.env

logf LOG.DATABASE, "{#ff8032-fg}Creating{/} connection..."
connection = if pe.LOCAL
then new Sequelize "postgres://#{pe.DB_USER}:#{pe.DB_PASS}@localhost:5432/sorbot-dev"
else new Sequelize "postgres://sorbot:#{pe.DB_PASS}@localhost:5432/sorbot"

logf LOG.DATABASE, "{#ff8032-fg}Defining{/} User model..."
User              connection
logf LOG.DATABASE, "{#ff8032-fg}Defining{/} FederatedMetadata model..."
FederatedMetadata connection

logf LOG.DATABASE, "{#ff8032-fg}Syncing{/} connection..."
connection.sync()
  .then logf LOG.DATABASE, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Dank database connection established{/}"
  .catch (err) -> logf LOG.DATABASE, "{#ff6432-fg}{bold}#{CROSSMARK}{/bold} Haha yesn't:{/} #{err}"


module.exports = {
  connection
  User
  FederatedMetadata
}
