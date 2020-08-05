{ Sequelize }            = require "sequelize"
{ red, green }           = require "ansi-colors-ts"
{ CROSSMARK, CHECKMARK } = require "../utils"

connection = if process.env.LOCAL
then new Sequelize "sqlite::memory:"
else new Sequelize "postgres://postgres:#{process.env.DB_PASS}@localhost:5432/sorbot"

connection.sync()
  .then console.log green (bold CHECKMARK) + " Dank database connection established"
  .catch (err) -> console.error (red (bold CROSSMARK) + " Haha yesn't:"), err

module.exports = connection
