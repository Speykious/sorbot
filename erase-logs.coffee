{ writeFileSync }	= require "fs"
{ LOG } = require "./src/utilog"

erase = (path) -> writeFileSync path, "", "utf8"
logpaths = Object.values LOG

logpaths.forEach erase