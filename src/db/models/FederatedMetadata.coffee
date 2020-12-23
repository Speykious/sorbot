{ DataTypes }     = require "sequelize"
{ encryptid }     = require "../../encryption"
{ ARRAY, BIGINT } = DataTypes

module.exports = (connection) ->
  connection.define "FederatedMetadata", {
    id:
      type: STRING 44
      primaryKey: yes
      set: (value) -> @setDataValue "id", encryptid value
    unverified:
      type: BIGINT
    member:
      type: BIGINT
    professor:
      type: BIGINT
    former:
      type: BIGINT
  }
