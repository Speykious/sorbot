{ writeFileSync }	= require "fs"
{ LOG } = require "./src/utilog"

erase = (path) ->
  writeFileSync path, "", "utf8"
  console.log "Erased file", path
logpaths = Object.values LOG

logpaths.forEach erase