function content (files) {
  return (name) => files[name] ? files[name].contents.toString() : '!!!' + name
}

function extension (name) {
  var rx = new RegExp('\.' + name + '$')
  return function (name) { return rx.exec(name) }
}

function storeJSON (json) {
  return { json: json, contents: new Buffer(JSON.stringify(json, null, 2)) }
}

var PERS = ['dt', 'tdc']
var path = {
  harmony: (title) => PERS.map((p) => 'rs200_harmony/' + title + '_' + p + '.har'),
  chords: (title) => PERS.map((p) => 'rs200_harmony_exp/' + title + '_' + p + '.txt')
}

module.exports = { extension, storeJSON, content, path }
