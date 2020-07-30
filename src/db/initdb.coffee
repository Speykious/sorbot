{ Sequelize } = require "sequelize"

connection = if process.env.LOCAL then new Sequelize("sqlite::memory:") else new Sequelize("postgres://postgres:#{process.env.DB_PASS}@localhost:5432/sorbot")

module.exports = connection
