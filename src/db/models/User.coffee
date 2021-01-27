{ DataTypes }           = require "sequelize"
{ encryptid }           = require "../../encryption"
{ USER_TYPES, DOMAINS } = require "../../constants"
{ ARRAY, SMALLINT, BIGINT, STRING } = DataTypes

module.exports = (connection) ->
  connection.define "User", {
    id:
      type: STRING 44
      primaryKey: yes
      set: (value) -> @setDataValue "id", encryptid value
    roletags:
      type: ARRAY STRING 16
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
        @setDataValue "email", value
        unless value then return
        
        domain = (value.split '@')[1]
        roletags = @getDataValue "roletags"
        if domain in DOMAINS.studentDomains   then roletags.push "student"
        if domain in DOMAINS.professorDomains then roletags.push "professor"
        @setDataValue "roletags", roletags
    code:
      type: STRING 6
    servers:
      type: ARRAY BIGINT
  }

