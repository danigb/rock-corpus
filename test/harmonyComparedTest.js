var vows = require('vows')
var harmony = require('../lib/harmony')
var assert = require('assert')
var fs = require('fs')
var path = require('path')
require('colors')
var jsdiff = require('diff')

var files = fs.readdirSync(path.join(__dirname, '../data/rs200_harmony_exp'))
  .map(function (file) { return file.slice(0, -4) })

function integrationTest () {
  files.forEach(function (name) {
    var srcFile = path.join(__dirname, '../data/rs200_harmony', name + '.har')
    var expFile = path.join(__dirname, '../data/rs200_harmony_exp', name + '.txt')
    var source = harmony(fs.readFileSync(srcFile).toString()).resolveStr('S')
    var expected = fs.readFileSync(expFile).toString()
    var diff = jsdiff.diffChars(source, expected)
    diff.forEach(function (part) {
      // green for additions, red for deletions
      // grey for common parts
      var color = part.added ? 'green'
      : part.removed ? 'red' : 'grey'
      process.stderr.write(part.value[color])
    })
    assert.equal(source, expected)
  })
}

vows.describe('Integration').addBatch({}).export(module)
