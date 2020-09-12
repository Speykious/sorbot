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
    code:
      type: STRING 6
    federatedServers:
      type: ARRAY BIGINT
  }, {
    validate:
      validateEmail: ->
        unless @email isnt null or
            @userType & (USER_TYPES.FORMER | USER_TYPES.GUEST) or
            not @userType
          throw new Error "Une adresse mail doit être renseignée pour ce type d'utilisateur."
        unless @email then return
        
        if (@email.split '@')[1] in DOMAINS.studentDomains   then @userType |= USER_TYPES.STUDENT
        if (@email.split '@')[1] in DOMAINS.professorDomains then @userType |= USER_TYPES.PROFESSOR
        console.log "@userType:", (@userType.toString 2)
        
        unless (@email.split '@')[1] in DOMAINS.studentDomains or
               (@email.split '@')[1] in DOMAINS.professorDomains
          throw new Error "Ceci n'est pas une adresse mail de Sorbonne Jussieu."
  }

