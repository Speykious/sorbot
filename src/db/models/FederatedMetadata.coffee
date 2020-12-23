{ DataTypes }     = require "sequelize"
{ BIGINT } = DataTypes

module.exports = (connection) ->
  connection.define "FederatedMetadata", {
    id:
      type: BIGINT
      primaryKey: yes
    unverified:
      type: BIGINT
    member:
      type: BIGINT
    professor:
      type: BIGINT
    former:
      type: BIGINT
  }
