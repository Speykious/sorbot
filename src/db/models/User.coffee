{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb.coffee"

User = connection.define ("User", {
  id: {
    type: DataTypes.BIGINT,
    primaryKey: true
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true
  },
  code: {
    type: DataTypes.STRING
  },
  federatedServers: {
    type: DataTypes.ARRAY(DataTypes.BIGINT)
  }
})

module.exports = User
