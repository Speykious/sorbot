{ Sequelize, DataTypes }    = require "sequelize"
{ CROSSMARK, CHECKMARK }    = require "../constants"
{ logf, LOG, formatCrisis } = require "../logging"
{ format }                  = require "util"

pe = process.env

connection = if pe.LOCAL
then new Sequelize "postgres://#{pe.USER}:#{pe.DB_PASS}@localhost:5432/sorbot-dev"
else new Sequelize "postgres://sorbot:#{pe.DB_PASS}@localhost:5432/sorbot"

connection.sync()
  .then logf LOG.DATABASE, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Dank database connection established{/}"
  .catch (err) -> logf LOG.DATABASE, "{#ff6432-fg}{bold}#{CROSSMARK}{/bold} Haha yesn't:{/} #{err}"

module.exports = connection
