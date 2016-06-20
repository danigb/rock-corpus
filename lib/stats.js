var utils = require('./utils')
var asArr = require('as-arr')

module.exports = function (files) {
  var songs = files['songs.json'].json
  var stats = { keys: {}, meters: {} }
  Object.keys(songs).forEach(function (title) {
    var song = songs[title]
    collectKeys(stats, song)
    collectMeters(stats, song)
  })
  files['stats.json'] = utils.storeJSON(stats)
}

function collectKeys (stats, song) {
  return asArr(song.key).map(function (k) {
    stats.keys[k] = stats.keys[k] || 0
    stats.keys[k]++
  })
}

function collectMeters (stats, song) {
  return asArr(song.meter).map(function (m) {
    stats.meters[m] = stats.meters[m] || 0
    stats.meters[m]++
  })
}
