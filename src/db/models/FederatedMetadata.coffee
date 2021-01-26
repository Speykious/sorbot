{ DataTypes } = require "sequelize"
{ BIGINT, STRING } = DataTypes
THICCINT = BIGINT
THICCSTRING = STRING 512

module.exports = (connection) ->
  connection.define "FederatedMetadata", {
    id:           # ID of the server
      type: THICCINT
      primaryKey: yes
    rtfm:         # ID of the RTFM category
      type: THICCINT
    rtfms:        # IDs of channels and messages of the RTFMs in a custom format
      type: THICCSTRING
    description:  # Description of the server for the 'accueil' page
      type: THICCSTRING
    roles:        # Lines of roleid:roletag associations
      type: THICCSTRING
  }
