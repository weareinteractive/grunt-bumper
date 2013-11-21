"use strict"

chai = require('chai')
grunt = require('grunt')

assert = chai.assert
chai.Assertion.includeStack = true

# See http://visionmedia.github.io/mocha/ for Mocha tests.
# See http://chaijs.com/api/assert/ for Chai assertion types.

comparePackages = (test, pkg) ->
  actual = grunt.file.read("test/tmp/#{test}/#{pkg}.json")
  expected = grunt.file.read("test/expected/#{test}/#{pkg}.json")
  assert.equal actual, expected, "Should bump the patch version in #{pkg}.json."

compareVersion = (test) ->
  actual = grunt.file.read("test/tmp/#{test}/version.txt")
  assert.equal actual, grunt.file.readJSON("test/tmp/#{test}/package.json").version, "Should update the package config version."

module.exports =
  "Test bumper":
    "patch": (done) ->
      compareVersion("patch")
      comparePackages("patch", "bower")
      comparePackages("patch", "package")
      done()
    "minor": (done) ->
      compareVersion("minor")
      comparePackages("minor", "bower")
      comparePackages("minor", "package")
      done()
    "major": (done) ->
      compareVersion("major")
      comparePackages("major", "bower")
      comparePackages("major", "package")
      done()
