{ Sequelize } = require "sequelize"

# maintenanceMode = process.env.MAINTENANCE_MODE
# connection = if maintenanceMode then new Sequelize("sqlite::memory:") else new Sequelize("postgres://postgres:#{process.env.DB_PASS}@localhost:5432/sorbot")
connection = new Sequelize("sqlite::memory")

module.exports = connection
