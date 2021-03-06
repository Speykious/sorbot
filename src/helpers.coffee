{ resolve }                     = require "path"
{ readFileSync, writeFileSync } = require "fs"

relative = (s) -> resolve __dirname, "../", s
delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

forEach = (array, f) ->
  promises = []
  for element in array
    promises.push f element
  return Promise.all promises

readf  = (path)       -> readFileSync  (relative path), "utf8"
writef = (path, data) -> writeFileSync (relative path), data, "utf8"

removeElement = (arr, element) ->
  i = arr.indexOf element
  if i isnt -1 then arr.splice i, 1
  return arr

setAdd = (set, element) ->
  unless element in set then set.push element

module.exports = {
  relative
  delay
  forEach
  readf
  writef
  removeElement
  setAdd
}