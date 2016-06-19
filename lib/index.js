var metalsmith = require('metalsmith')

function extension (name) {
  var rx = new RegExp('\.' + name + '$')
  return function (name) { return rx.exec(name) }
}

var isJson = extension('json')
var isHar = extension('har')
var isMel = extension('mel')

metalsmith(__dirname)
  .source('../data')
  .destination('../corpus')
  .use(songTitles)
  // leave only json files
  .use(onlyJsonFiles)
  .build(function (err) {
    if (err) throw err
    console.log('Build finished.')
  })

function songTitles (files) {
  var titles = {}
  for (var name in files) {
    if (isHar(name) || isMel(name)) {
      var text = files[name].contents.toString()
      var match = /^\s*%.*$/m.exec(text)
      if (match) {
        var title = match[0].trim().slice(1).trim()
        titles[title] = titles[title] || []
        titles[title].push(name)
      }
    }
  }
  files['titles.json'] = { contents: new Buffer(JSON.stringify(titles, null, 2)) }
}

// leave only json files
function onlyJsonFiles (files) {
  for (var name in files) {
    if (!isJson(name)) delete files[name]
  }
}
