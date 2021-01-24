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
    unverified:   # ID of the unverified role
      type: THICCINT
    member:       # ID of the verified role
      type: THICCINT
    professor:    # ID of the professor role
      type: THICCINT
    former:       # ID of the former role
      type: THICCINT
  }
