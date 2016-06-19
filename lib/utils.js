
function extension (name) {
  var rx = new RegExp('\.' + name + '$')
  return function (name) { return rx.exec(name) }
}

function toFiles (json) {
  return { contents: new Buffer(JSON.stringify(json, null, 2)) }
}

module.exports = { extension, toFiles }
