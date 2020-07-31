{ Sequelize }            = require "sequelize"
connection               = require "./initdb.coffee"
{ red, green }           = require "ansi-colors-ts"
{ CROSSMARK, CHECKMARK } = require "../utils"

connection.sync()
  .then console.log green CHECKMARK + " Dank database connection established"
  .catch (err) -> console.error (red CROSSMARK + " Haha yesn't:"), err
