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
    isEmail: true
    unique: true
  
  code:
    type: STRING
  
  federatedServers:
    type: ARRAY BIGINT
}

module.exports = User
