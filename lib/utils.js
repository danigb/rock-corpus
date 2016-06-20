
function extension (name) {
  var rx = new RegExp('\.' + name + '$')
  return function (name) { return rx.exec(name) }
}

function storeJSON (json) {
  return { json: json, contents: new Buffer(JSON.stringify(json, null, 2)) }
}

module.exports = { extension, storeJSON }
