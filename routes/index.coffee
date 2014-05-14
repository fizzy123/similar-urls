
#
# * GET home page.
# 
exports.index = (req, res) ->
  jsonResponse = [
    {key1: "value1", key2: "value2"}
    {key1: "value3", key2: "value4"}
  ]
  res.set('Content-Type': 'application/json')
  res.send(jsonResponse)
  return
