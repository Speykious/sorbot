forEach = (array, f) ->
  promises = []
  for element of array
    promises.push (f element)
  return Promise.all promises


module.exports = forEach