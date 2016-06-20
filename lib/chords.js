var utils = require('./utils')

module.exports = function (metal) {
  var files = metal['files.json'].json
  var chords = {}
  Object.keys(files).forEach(function (title) {
    var chord = chords[title] = {}
    chord.title = title
    var contents = utils.path.chords(files[title]).map(utils.content(metal))
    chord.harmony = contents
    var c = contents.map(function (harmony) {
      return harmony.split(/\s*\|\s*/)
    })
  })
  metal['chords.json'] = utils.storeJSON(chords)
}
