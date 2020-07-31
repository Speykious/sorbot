forEach = (array, f) ->
  promises = []
  for element in array
    promises.push (f element)
  return Promise.all promises


module.exports = forEach