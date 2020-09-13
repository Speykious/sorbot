{ DataTypes }           = require "sequelize"
{ encryptid }           = require "../../encryption"
{ USER_TYPES, DOMAINS } = require "../../constants"
{ ARRAY, SMALLINT, BIGINT, STRING } = DataTypes

module.exports = (connection) ->
  connection.define "User", {
    id:
      type: STRING 44
      primaryKey: yes
      set: (value) -> @setDataValue 'id', encryptid value
    userType:
      type: SMALLINT
    reactor:
      type: BIGINT
    email:
      type: STRING
      unique: yes
      validate:
        isEmail:
          msg: "Ceci n'est pas une adresse mail."
        validateEmail: (value) ->
          domain = (value.split '@')[1]
          unless domain in DOMAINS.studentDomains or
                 domain in DOMAINS.professorDomains
            throw new Error "Ceci n'est pas une adresse mail de Sorbonne Jussieu."
      set: (value) ->
        @setDataValue 'email', value
        unless value then return
        
        domain = (value.split '@')[1]
        userType = @getDataValue 'userType'
        if domain in DOMAINS.studentDomains   then userType |= USER_TYPES.STUDENT
        if domain in DOMAINS.professorDomains then userType |= USER_TYPES.PROFESSOR
        @setDataValue 'userType', userType
    code:
      type: STRING 6
    federatedServers:
      type: ARRAY BIGINT
  }

