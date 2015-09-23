var trim = (e) => { return e.trim() }
var isNotEmpty = (e) => { return e.length > 0 }

function Harmony (data) {
  if (!(this instanceof Harmony)) return new Harmony(data)
  this.data = data
  this.parts = {}
  data.trim().split('\n').map(trim).filter(isNotEmpty)
    .forEach((line) => {
      if (/^%/.test(line)) this.title = this.title || line.substring(1).trim()
      else if (line.indexOf(':') > 0) {
        var s = line.split(':')
        this.parts[s[0]] = parseMeasures(s[1].replace(/%.*$/, '').trim())
      }
    })
}

Harmony.prototype.resolveStr = function (name) {
  return this.resolve(name).map((measure) => {
    return measure.join(' ')
  }).join(' | ') + ' |'
}
Harmony.prototype.resolve = function (name) {
  var measures = []
  this.expand(name).forEach((m) => {
    var measure = []
    m.forEach((item) => {
      if (/^\$/.test(item)) {
        item = this.resolve(item.substring(1))
        if (measure.length) {
          item[0] = item[0] ? measure.concat(item[0]) : measures
          measure = []
        }
        measures = measures.concat(item)
      } else {
        measure.push(item)
      }
    })
    if (measure.length) measures.push(measure)
  })
  return measures
}

Harmony.prototype.expand = function (name) {
  var times, prevMeasure, split
  var measures = []
  this.parts[name].forEach(function (m, mIndex) {
    var measure = []
    m.forEach(function (item, index) {
      if (item === '.') {
        measure.push(measure[measure.length - 1])
      } else if (index === 0 && /^\*\d+$/.test(item)) {
        prevMeasure = measures[measures.length - 1]
        times = +item.substring(1) - 1
        while (times--) measures.push(prevMeasure)
      } else if (/^\$[^*]+\*\d+$/.test(item)) {
        split = item.split('*')
        times = +split[1]
        while (times--) measure.push(split[0])
      } else {
        measure.push(item)
      }
    })
    measures.push(measure)
  })
  return measures
}

function parseMeasures (measures) {
  measures = measures.replace(/^\s*\|/, '').replace(/\|\s*$/, '')
  var parseMeasure = (m) => { return m.split(' ').map(trim) }

  return measures.split('|').map(trim).map(parseMeasure)
}

module.exports = Harmony
