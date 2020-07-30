{ Sequelize } = require "sequelize"
connection = require "./initdb.coffee"

connection.sync()
  .then console.log "Dank database connection established"
  .catch (error) -> console.error "Haha yesn't: " + error
