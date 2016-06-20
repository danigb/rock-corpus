var utils = require('./utils')

var PERS = ['dt', 'tdc']
function harmony (title) {
  return PERS.map((p) => 'rs200_harmony/' + title + '_' + p + '.har')
}
function content (files) {
  return (name) => files[name].contents.toString()
}
function combine (a, b) { return a === b ? a : [a, b] }

module.exports = function (files) {
  var titles = files['titles.json'].json
  var songs = {}
  Object.keys(titles).forEach(function (title) {
    var song = songs[title] = {}
    song.title = title
    var contents = harmony(titles[title]).map(content(files))
    song.key = contents.map(getKey).reduce(combine)
    song.meter = contents.map(getMeter).reduce(combine)
  })
  files['songs.json'] = utils.storeJSON(songs)
}

function getKey (text) {
  text = text.split('S:')[1]
  var m = /\[([a-zA-Z#]+)\]/.exec(text)
  return m ? m[1] : null
}

function getMeter (text) {
  text = text.split('S:')[1]
  var m = /\[([\d+\/\d+]+)\]/.exec(text)
  return m ? m[1] : '4/4'
}
