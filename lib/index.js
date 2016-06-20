var metalsmith = require('metalsmith')
var utils = require('./utils')
var songs = require('./songs')
var stats = require('./stats')
var songTitles = require('./song-titles')

var isJson = utils.extension('json')

metalsmith(__dirname)
  .source('../data')
  .destination('../corpus')
  // PLUGINS
  .use(songTitles)
  .use(songs)
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
