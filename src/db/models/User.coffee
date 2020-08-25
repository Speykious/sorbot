{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb"

{ BIGINT, STRING, ARRAY } = DataTypes

User = connection.define "User", {
  id:
    type: STRING 64
    primaryKey: yes
  email:
    type: STRING
    allowNull: no
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
