{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb"
{ encryptid } = require "../../encryption.coffee"

{ BIGINT, STRING, ARRAY } = DataTypes

User = connection.define "User", {
  id:
    type: STRING 64
    primaryKey: yes
    set: (value) ->
      @setDataValue 'id', encryptid value
      return
  email:
    type: STRING
    # allowNull: no
    unique: yes
    validate:
      isEmail: yes
  code:
    type: STRING 6
  federatedServers:
    type: ARRAY BIGINT
  menuState:
    type: STRING
}

module.exports = User
