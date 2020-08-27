{ resolve }                 = require "path"
{ format }                  = require "util"
fs                          = require "fs"

relative = (s) -> resolve __dirname, "../", s
delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

forEach = (array, f) ->
  promises = []
  for element in array
    promises.push f element
  return Promise.all promises

readf  = (path)       -> fs.readFileSync  (relative path), "utf8"
writef = (path, data) -> fs.writeFileSync (relative path), data, "utf8"



module.exports = {
  relative
  delay
  forEach
  readf
  writef
}