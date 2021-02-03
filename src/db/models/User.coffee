{ DataTypes }           = require "sequelize"
{ encryptid }           = require "../../encryption"
{ USER_TYPES, DOMAINS } = require "../../constants"
{ setAdd }          = require "../../helpers"
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
    code:
      type: STRING 6
    servers:
      type: ARRAY BIGINT
  }

