require "dotenv-flow"
.config()

{ Sequelize, DataTypes } = require "sequelize"
{ decryptid, encryptid } = require "./encryption"
{ DOMAINS } = require "./constants"
{ ARRAY, SMALLINT, BIGINT, STRING } = DataTypes
{ blue, green } = require "ansi-colors-ts"

pe = process.env
uri = if pe.LOCAL
then "postgres://#{pe.DB_USER}:#{pe.DB_PASS}@localhost:5432/sorbot-dev"
else "postgres://sorbot:#{pe.DB_PASS}@localhost:5432/sorbot"
connection = new Sequelize uri

OldUser = connection.define "User", {
  id:
    type: STRING 44
    primaryKey: yes
  type:
    type: SMALLINT
  reactor:
    type: BIGINT
  email:
    type: STRING
    unique: yes
    validate:
      isEmail:
        msg: "Ceci n'est pas une adresse mail."
  code:
    type: STRING 6
  servers:
    type: SMALLINT
}

NewUser = connection.define "NewUser", {
  id:
    type: STRING 44
    primaryKey: yes
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

connection.sync()
  .then ->
    console.log "Dank database connection established"
    await query()
  .catch (err) ->
    console.log "\x1b[31m Haha yesn't:\x1b[0m #{err}"
    process.exit 1

USER_TYPES =
  STUDENT:   1 << 0
  PROFESSOR: 1 << 1
  GUEST:     1 << 2
  FORMER:    1 << 3

query = ->
  oldUsers = await OldUser.findAll()
  i = 0
  for { id, type, reactor, email, code, servers, createdAt, updatedAt } in oldUsers
    decrypted = null
    try
      decrypted = decryptid id # Ensuring the id is decryptable
      
    catch e
      console.log "\x1b[31mERROR:\x1b[0m #{e} with OldUser", {
        id, type, reactor, email, code, servers, createdAt, updatedAt, decrypted
      }
    
    i++
    roletags = []
    if type then roletags.push "member"
    if type & USER_TYPES.STUDENT then roletags.push "student"
    if type & USER_TYPES.PROFESSOR then roletags.push "professor"
    if type & USER_TYPES.GUEST then roletags.push "guest"
    if type & USER_TYPES.FORMER then roletags.push "former"
    unless roletags.length then roletags.push "unverified"
    console.log i, "#{(green id)}(#{id.length})", roletags, reactor, email, code, ["672479260899803147"], createdAt, updatedAt
    await NewUser.create {
      id, roletags, reactor, email, code
      servers: ["672479260899803147"]
      createdAt, updatedAt
    }
