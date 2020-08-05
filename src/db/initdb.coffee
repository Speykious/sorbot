{ Sequelize }            = require "sequelize"
{ red, green }           = require "ansi-colors-ts"
{ logf, LOG, formatCrisis } = require "../logging"
{ CROSSMARK, CHECKMARK } = require "../utils"

connection = if process.env.LOCAL
then new Sequelize "sqlite::memory:"
else new Sequelize "postgres://postgres:#{process.env.DB_PASS}@localhost:5432/sorbot"

connection.sync()
  .then logf LOG.DATABASE, "{#32ff64-fg}{bold}#{CHECKMARK}{/bold} Dank database connection established{/}"
  .catch (err) -> logf LOG.DATABASE, "{#ff6432-fg}{bold}#{CROSSMARK}{/bold} Haha yesn't:{/} #{err}"

module.exports = connection
