{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb.coffee"

{ BIGINT, STRING, ARRAY } = DataTypes

User = connection.define "User", {
  id:
    type: BIGINT
    primaryKey: true
  email:
    type: STRING
    allowNull: false
    unique: true
    validate:
      isEmail: true
  code:
    type: STRING
  federatedServers:
    type: ARRAY BIGINT
  menuState:
    type: STRING
}

module.exports = User
