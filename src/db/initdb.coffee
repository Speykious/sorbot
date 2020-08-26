{ Sequelize }               = require "sequelize"
{ CROSSMARK, CHECKMARK }    = require "../constants"
{ logf, LOG, formatCrisis } = require "../logging"

connection = if process.env.LOCAL
then new Sequelize "postgres://postgres:#{process.env.DB_PASS}@localhost:5432/sorbot-dev"
else new Sequelize "postgres://postgres:#{process.env.DB_PASS}@localhost:5432/sorbot"

connection.sync()
  .then logf LOG.DATABASE, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Dank database connection established{/}"
  .catch (err) -> logf LOG.DATABASE, "{#ff6432-fg}{bold}#{CROSSMARK}{/bold} Haha yesn't:{/} #{err}"

module.exports = connection
