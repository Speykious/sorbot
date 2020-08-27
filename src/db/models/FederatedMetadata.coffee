{ Sequelize, DataTypes } = require "sequelize"
connection = require "../initdb"

{ ARRAY }  = DataTypes
{ BIGINT } = DataTypes.postgres

FederatedMetadata = connection.define "FederatedMetadata", {
  id:
    type: BIGINT
    primaryKey: yes
  requiredRoles:
    type: ARRAY ARRAY BIGINT
}

module.exports = FederatedMetadata
