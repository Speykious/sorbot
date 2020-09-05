{ DataTypes }           = require "sequelize"
{ encryptid }           = require "../../encryption"
{ USER_TYPES, DOMAINS } = require "../../constants"
{ ARRAY, SMALLINT, BIGINT, STRING } = DataTypes

module.exports = (connection) ->
  connection.define "User", {
    id:
      type: STRING 44
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
        isEmail:
          msg: "Ceci n'est pas une adresse mail."
        isUniversityEmail: (value) ->
          @userType |= USER_TYPES.STUDENT if (value.split '@')[1] in DOMAINS.studentDomains
          @userType |= USER_TYPES.PROFESSOR if (value.split '@')[1] in DOMAINS.professorDomains
          unless (value.split '@')[1] in DOMAINS.studentDomains or
                 (value.split '@')[1] in DOMAINS.professorDomains
            throw new Error "Ceci n'est pas une adresse mail de Sorbonne Jussieu."

        canBeNull: (value) ->
          unless value isnt null or
              @userType & (USER_TYPES.FORMER | USER_TYPES.GUEST) or
              not @userType
            throw new Error "Une adresse mail doit être renseignée pour ce type d'utilisateur."
    code:
      type: STRING 6
    federatedServers:
      type: ARRAY BIGINT
    menuState:
      type: STRING
  }

