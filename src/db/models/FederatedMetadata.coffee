{ DataTypes } = require "sequelize"
{ BIGINT, STRING } = DataTypes
THICCINT = BIGINT
THICCSTRING = STRING 512

module.exports = (connection) ->
  connection.define "FederatedMetadata", {
    id:
      type: THICCINT
      primaryKey: yes
    rtfm:
      type: THICCINT
    rtfms:
      type: THICCSTRING
    unverified:
      type: THICCINT
    member:
      type: THICCINT
    professor:
      type: THICCINT
    former:
      type: THICCINT
  }
