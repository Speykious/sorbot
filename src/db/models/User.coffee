{ DataTypes }           = require "sequelize"
{ encryptid }           = require "../../encryption"
{ USER_TYPES, DOMAINS } = require "../../constants"
{ ARRAY, SMALLINT, BIGINT, STRING } = DataTypes

module.exports = (connection) ->
  connection.define "User", {
    id:
      type: STRING 64
      primaryKey: yes
      set: (value) ->
        @setDataValue 'id', encryptid value
        return
    userType:
      type: SMALLINT
    email:
      type: STRING
      unique: yes
      validate:
        isEmail: yes
        isUniversityEmail: (value) ->
          unless (value.split '@')[1] in DOMAINS.studentDomains or
                (value.split '@')[1] in DOMAINS.professorDomains
            throw new Error "Not a university email address"
        canBeNull: (value) ->
          unless @userType & USER_TYPES.FORMER or @userType & USER_TYPES.GUEST
            throw new Error "Email must be supplied for this user type"
    code:
      type: STRING 6
    federatedServers:
      type: ARRAY BIGINT
    menuState:
      type: STRING
  }

