var capitalize = require('capitalize')
var utils = require('./utils')

var isHar = utils.extension('har')
var isMel = utils.extension('mel')

// Create a JSON file with the song titles
// mapped to the file names
module.exports = function (files) {
  var names = {}
  for (var name in files) {
    if (isHar(name) || isMel(name)) {
      var split = name.split('/')[1].split(/_(dt|tdc)/)
      var fileName = split[0]
      if (!names[fileName]) names[fileName] = getTitle(files[name])
    }
  }
  var reverse = Object.keys(names).reduce(function (t, k) {
    t[names[k]] = k
    return t
  }, {})
  files['files.json'] = utils.storeJSON(reverse)
}

function getTitle (file) {
  var text = file.contents.toString()
  var match = /^\s*%.*$/m.exec(text)
  return match ? capitalize.words(match[0].trim().slice(1).trim()) : null
}
