{ writeFileSync }	= require "fs"
{ LOG } = require "./src/logging"

erase = (path) ->
  writeFileSync path, "", "utf8"
  console.log "Erased file", path
logpaths = Object.values LOG

logpaths.forEach erase