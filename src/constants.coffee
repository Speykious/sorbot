YAML        = require "yaml"
{ readf }   = require "./helpers"
{ version } = require "../package.json"

# This is the most CAPITAListic file that we'll ever have

CHECKMARK = "🗸"
CROSSMARK = "✗"

TESTERS = [
  "358960666238910465" # Speykious
  "654002031538864151" # Spey's Role Manager
  "128848040889942016" # chilledfrogs
  "419624396710477834" # Toast
  "690223603001983037" # Ereshkigall
]

DOMAINS = YAML.parse readf "resources/domains.yaml"
SERVERS = YAML.parse readf "resources/servers.yaml"
BYEBYES = (readf "resources/byebye.md").split "\n"
GUILDS = {}
FOOTER =
  iconURL: "https://i.imgur.com/e3K2oaW.png"
  text: "SorBOT [v#{version}]"

module.exports = {
  CHECKMARK
  CROSSMARK
  TESTERS
  DOMAINS
  SERVERS
  BYEBYES
  GUILDS
  FOOTER
}
