var capitalize = require('capitalize')
var utils = require('./utils')

var isHar = utils.extension('har')
var isMel = utils.extension('mel')

// Create a JSON file with the song titles
// mapped to the file names
module.exports = function (files) {
  var fileNames = {}
  for (var name in files) {
    if (isHar(name) || isMel(name)) {
      var split = name.split('/')[1].split(/_(dt|tdc)/)
      var fileName = split[0]
      if (!fileNames[fileName]) fileNames[fileName] = getTitle(files[name])
    }
  }
  var titles = Object.keys(fileNames).reduce(function (t, k) {
    t[fileNames[k]] = k
    return t
  }, {})
  files['titles.json'] = utils.toFiles(titles)
}

function getTitle (file) {
  var text = file.contents.toString()
  var match = /^\s*%.*$/m.exec(text)
  return match ? capitalize.words(match[0].trim().slice(1).trim()) : null
}
