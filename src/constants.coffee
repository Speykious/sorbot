YAML      = require "yaml"
{ readf } = require "./helpers"

# This is the most CAPITAListic file that we'll ever have

CHECKMARK = "🗸"
CROSSMARK = "✗"

TESTERS = [
  "358960666238910465" # Speykious
  "654002031538864151" # Spey's Role Manager
  "419624396710477834" # Toast
  "194549333226422272" # Théo B.
]

DOMAINS = YAML.parse readf "resources/domains.yaml"
SERVERS = YAML.parse readf "resources/servers.yaml"
GUILDS = {}

USER_TYPES =
  STUDENT:   1 << 0
  PROFESSOR: 1 << 1
  GUEST:     1 << 2
  FORMER:    1 << 3

module.exports = {
  CHECKMARK
  CROSSMARK
  TESTERS
  DOMAINS
  SERVERS
  USER_TYPES
  GUILDS
}
