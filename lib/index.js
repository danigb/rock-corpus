var metalsmith = require('metalsmith')
var utils = require('./utils')
var chords = require('./chords')
var songs = require('./songs')
var stats = require('./stats')
var files = require('./files')

var isJson = utils.extension('json')

metalsmith(__dirname)
  .source('../source/data')
  .destination('../corpus')
  // PLUGINS
  .use(files)
  .use(songs)
  .use(chords)
  .use(stats)
  // leave only json files
  .use(onlyJsonFiles)
  .build(function (err) {
    if (err) throw err
    console.log('Build finished.')
  })

// leave only json files
function onlyJsonFiles (files) {
  for (var name in files) {
    if (!isJson(name)) delete files[name]
  }
}
