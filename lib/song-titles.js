var capitalize = require('capitalize')
var utils = require('./utils')

var isHar = utils.extension('har')
var isMel = utils.extension('mel')

// Create a JSON file with the song titles
// mapped to the file names
module.exports = function (files) {
  var titles = {}
  for (var name in files) {
    if (isHar(name) || isMel(name)) {
      var text = files[name].contents.toString()
      var match = /^\s*%.*$/m.exec(text)
      if (match) {
        var title = capitalize.words(match[0].trim().slice(1).trim())
        console.log(title)
        titles[title] = titles[title] || []
        titles[title].push(name)
      }
    }
  }

  files['titles.json'] = utils.toFiles(titles)
}
