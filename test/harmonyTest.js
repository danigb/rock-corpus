var vows = require('vows')
var assert = require('assert')
var harmony = require('../lib/harmony')

vows.describe('Harmony').addBatch({
  'parse measures': {
    'simple measure': function () {
      assert.deepEqual(harmony('s: a | b').parts.s, [ [ 'a' ], [ 'b' ] ])
    },
    'empty measures': function () {
      assert.deepEqual(harmony('s:|  |').parts.s, [ [''] ])
    },
    'divide measure contents': function () {
      var data = 'InP: I64 V11 | I64 V11 |'
      assert.deepEqual(harmony(data).parts.InP, [ [ 'I64', 'V11' ], [ 'I64', 'V11' ] ])
    },
    'handle multiple parts': function () {
      var data = 'A: a | b\nB: c |'
      assert.deepEqual(harmony(data).parts, {
        'A': [['a'], ['b']],
        'B': [['c']]
      })
    },
    'empty lines and line trim': function () {
      var data = '\n     A: a\n\n     B:     c'
      assert.deepEqual(harmony(data).parts['A'], [ ['a'] ])
      assert.deepEqual(harmony(data).parts['B'], [ ['c'] ])
    }
  },
  'expand measures': {
    'handle asterisk': function () {
      var data = 'In: R | R|*2 $InP*2 $BP*1'
      assert.deepEqual(harmony(data).expand('In'), [['R'], ['R'], ['R'], ['$InP', '$InP', '$BP']])
    },
    'handle dots': function () {
      var data = 'A: a b . c'
      assert.deepEqual(harmony(data).expand('A'), [ ['a', 'b', 'b', 'c'] ])
    }
  },
  'resolve': {
    'resolve parts': function () {
      var data = 'A: a | b c\nS: $A*2'
      assert.deepEqual(harmony(data).resolve('A'), [ ['a'], ['b', 'c'] ])
      assert.deepEqual(harmony(data).resolve('S'), [ ['a'], ['b', 'c'], ['a'], ['b', 'c'] ])
    },
    'resolveStr': function () {
      var data = 'A: a | b c\nS: $A*2'
      assert.equal(harmony(data).resolveStr('S'), 'a | b c | a | b c |')
    },
    'resolve with data': function () {
      var data = 'A: a\nS: [E] $A*2'
      assert.equal(harmony(data).resolveStr('S'), '[E] a | a |')
    },
    'real example': function () {
      var data = `
      Vr: I | | ii7 | vi | I | ii7 . IV V/vi | vi | I |
      In: I V6 vi I64 | ii65 V43/ii ii vi6 bVIId7 . VId7 . | V |
      S: [Bb] [12/8] $In $Vr I |
      `
      var expected = '[Bb] [12/8] I V6 vi I64 | ii65 V43/ii ii vi6 bVIId7 bVIId7 VId7 VId7 | V | I |  | ii7 | vi | I | ii7 ii7 IV V/vi | vi | I | I |'
      var result = harmony(data).resolveStr('S')
      assert.equal(result, expected)
    }
  }
}).export(module)
