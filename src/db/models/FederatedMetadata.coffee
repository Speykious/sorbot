{ DataTypes } = require "sequelize"
THICCINT = DataTypes.BIGINT

module.exports = (connection) ->
  connection.define "FederatedMetadata", {
    id:
      type: THICCINT
      primaryKey: yes
    rtfm:
      type: THICCINT
    unverified:
      type: THICCINT
    member:
      type: THICCINT
    professor:
      type: THICCINT
    former:
      type: THICCINT
  }
