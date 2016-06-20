var utils = require('./utils')

function combine (a, b) { return a === b ? a : [a, b] }

module.exports = function (metal) {
  var files = metal['files.json'].json
  var songs = {}
  Object.keys(files).forEach(function (title) {
    var song = songs[title] = {}
    song.title = title
    var contents = utils.path.harmony(files[title]).map(utils.content(metal))
    song.key = contents.map(getKey).reduce(combine)
    song.meter = contents.map(getMeter).reduce(combine)
  })
  metal['songs.json'] = utils.storeJSON(songs)
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
