{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb"

{ BIGINT, ARRAY } = DataTypes

FederatedMetadata = connection.define "FederatedMetadata", {
  id:
    type: BIGINT
    primaryKey: yes
  requiredRoles:
    type: ARRAY ARRAY BIGINT
}

module.exports = FederatedMetadata
