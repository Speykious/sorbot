{ DataTypes }     = require "sequelize"
{ ARRAY, BIGINT } = DataTypes

module.exports = (connection) ->
  connection.define "FederatedMetadata", {
    id:
      type: BIGINT
      primaryKey: yes
    requiredRoles:
      type: ARRAY ARRAY BIGINT
  }
