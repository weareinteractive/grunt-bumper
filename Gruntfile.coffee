###
grunt-bumper
https://github.com/weareinteractive/grunt-bumper

Copyright (c) 2013 We Are Interactive
Licensed under the MIT license.
###

#global module
module.exports = (grunt) ->
  "use strict"

  # Project configuration.
  grunt.initConfig
    # The test package configuration as config property:
    pkg: grunt.file.readJSON "test/fixtures/package.json"

    coffeelint:
      files: ["Gruntfile.coffee", "tasks/**/*.coffee", "test/**/*.coffee"]
      options:
        max_line_length:
          value: 200
          level: "error"

    # Test clean
    clean:
      tests: ["test/tmp"]

    # Test copy
    copy:
      fixtures:
        expand: true
        cwd: "test/fixtures/"
        src: ["*.json"]
        dest: "test/tmp/"
      patch:
        expand: true
        cwd: "test/tmp/"
        src: ["*.json", "version.txt"]
        dest: "test/tmp/patch/"
      minor:
        expand: true
        cwd: "test/tmp/"
        src: ["*.json", "version.txt"]
        dest: "test/tmp/minor/"
      major:
        expand: true
        cwd: "test/tmp/"
        src: ["*.json", "version.txt"]
        dest: "test/tmp/major/"

    # Test bumping
    bumper:
      options:
        tasks: ["custom"]
        files: ["test/tmp/package.json", "test/tmp/bower.json"]

    # Unit tests.
    mochacov:
      options:
        bail: true
        ui: 'exports'
        require: 'coffee-script'
        compilers: ['coffee:coffee-script']
        files: 'test/specs/**/*.test.coffee'
      all:
        options:
          reporter: 'spec'

  # Actually load this plugin's task(s).
  grunt.loadTasks 'tasks'

  # Register custom task to test the package config version update and build tasks setting:
  grunt.registerTask "custom", ->
    grunt.file.write "test/tmp/version.txt", grunt.config("pkg.version")

  # Load npm tasks
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-mocha-cov"

  # Tasks
  grunt.registerTask "default", ["coffeelint"]
  grunt.registerTask "test", [
    "default"
    "clean"
    "copy:fixtures"
    "bumper-only:patch"
    "copy:patch"
    "bumper-only:minor"
    "copy:minor"
    "bumper-only:major"
    "copy:major"
    "mochacov"
  ]
