{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb.coffee"

{ BIGINT, STRING, ARRAY } = DataTypes

User = connection.define "User", {
  id:
    type: STRING 64
    primaryKey: true
  email:
    type: STRING
    allowNull: false
    unique: true
    validate:
      isEmail: true
  code:
    type: STRING 6
  federatedServers:
    type: ARRAY BIGINT
  menuState:
    type: STRING
}

module.exports = User
