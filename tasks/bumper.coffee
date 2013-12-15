###
Increase version number

grunt bumper
grunt bumper:git
grunt bumper:patch
grunt bumper:minor
grunt bumper:major

@author franklin <franklin@weareinteractive.com>
@author Vojta Jina <vojta.jina@gmail.com>
@author Mathias Paumgarten <mail@mathias-paumgarten.com>
@author Adam Biggs <email@adambig.gs>
@author Achim Sperling <achim.sperling@gmail.com>
###

semver = require("semver")
exec = require("child_process").exec

module.exports = (grunt) ->
  "use strict"

  grunt.registerTask "bumper", "Bump package version, run tasks, git tag, commit & push.", (versionType, incOrCommitOnly) ->

    opts = @options(
      bumpVersion: true
      files: ["package.json"]
      updateConfigs: ['pkg'] # array of config properties to update (with files)
      releaseBranch: false
      runTasks: true
      tasks: ["default"]
      add: true
      addFiles: ["."] # '.' for all files except ingored files in .gitignore
      commit: true
      commitMessage: "Release v%VERSION%"
      commitFiles: ["-a"] # '-a' for all files
      createTag: true
      tagName: "v%VERSION%"
      tagMessage: "Version %VERSION%"
      push: true
      pushTo: "origin"
      npm: false
      npmTag: "Release v%VERSION%"
      gitDescribeOptions: "--tags --always --abbrev=1 --dirty=-d"
    )

    if incOrCommitOnly is "bump-only"
      grunt.verbose.writeln "Only incrementing the version."
      opts.add = false
      opts.commit = false
      opts.createTag = false
      opts.push = false

    if incOrCommitOnly is "commit-only"
      grunt.verbose.writeln "Only commiting/tagging/pushing."
      opts.bumpVersion = false

    if incOrCommitOnly is "push-release"
      grunt.verbose.writeln "Pushing and publishing to NPM."
      opts.npm = true
    else
      opts.npm = false

    if incOrCommitOnly is "push-publish"
      grunt.verbose.writeln "Publishing to NPM."
      opts.bumpVersion = false
      opts.runTasks = false
      opts.add = false
      opts.commit = false
      opts.createTag = false
      opts.push = false
      opts.npm = true

    done = @async()
    queue = []

    next = ->
      return done() unless queue.length
      queue.shift()()

    runIf = (condition, behavior) ->
      queue.push(behavior) if condition

    # MAKE SURE WE'RE ON A RELEASE BRANCH
    runIf opts.releaseBranch, ->
      if opts.npm or opts.commit or opts.push
        exec "git rev-parse --abbrev-ref HEAD", (err, stdout, stderr) ->
          grunt.fatal "Cannot determine current branch."  if err or stderr
          currentBranch = stdout.trim()
          rBranches = (if (typeof opts.releaseBranch is "string") then [opts.releaseBranch] else opts.releaseBranch)
          rBranches.forEach (rBranch) ->
            next()  if rBranch is currentBranch

          grunt.warn "The current branch is not in the list of release branches."

          # Allow for --force
          next()

    globalVersion = undefined # when bumping multiple files
    gitVersion = undefined # when bumping using `git describe`
    VERSION_REGEXP = /(\bversion[\'\"]?\s*[:=]\s*[\'\"])([\da-z\.-]+)([\'\"])/i

    # GET VERSION FROM GIT
    runIf opts.bumpVersion and versionType is "git", ->
      exec "git describe " + opts.gitDescribeOptions, (err, stdout, stderr) ->
        grunt.fatal "Can not get a version number using `git describe`"  if err
        gitVersion = stdout.trim()
        next()

    # BUMP ALL FILES
    runIf opts.bumpVersion, ->
      opts.files.forEach (file, idx) ->
        version = null
        content = grunt.file.read(file).replace(VERSION_REGEXP, (match, prefix, parsedVersion, suffix) ->
          version = gitVersion or semver.inc(parsedVersion, versionType or "patch")
          prefix + version + suffix
        )
        grunt.fatal "Can not find a version to bump in " + file  unless version
        grunt.file.write file, content
        grunt.log.ok "Version bumped to " + version + ((if opts.files.length > 1 then " (in " + file + ")" else ""))

        unless globalVersion
          globalVersion = version
        else
          grunt.warn "Bumping multiple files with different versions!" if globalVersion isnt version

        configProperty = opts.updateConfigs[idx]

        return unless configProperty

        cfg = grunt.config(configProperty)
        return grunt.warn("Can not update \"" + configProperty + "\" config, it does not exist!")  unless cfg

        cfg.version = version
        grunt.config(configProperty, cfg)
        grunt.log.ok("#{configProperty}'s version updated")

      next()

    # RUN TASKS
    runIf opts.runTasks, ->
      grunt.log.ok("Running tasks: #{opts.tasks}")
      for task in opts.tasks
        grunt.util.spawn({grunt:true, args:[task]}, (error, result, code) ->
          if error?
            grunt.fail.fatal(result)
          else
            grunt.log.write(result)
            grunt.log.write("\n")
          next()
        )

    # when only commiting, read the version from package.json / pkg config
    runIf not opts.bumpVersion, ->
      if opts.updateConfigs.length
        globalVersion = grunt.config(opts.updateConfigs[0]).version
      else
        globalVersion = grunt.file.readJSON(opts.files[0]).version
      next()

    # ADD
    runIf opts.add, ->
      exec "git add " + opts.addFiles.join(" "), (err, stdout, stderr) ->
        grunt.fatal "Can not add files:\n  " + stderr  if err
        grunt.log.ok "Added files: \"" + opts.addFiles.join(" ") + "\""
        next()

    # COMMIT
    runIf opts.commit, ->
      commitMessage = opts.commitMessage.replace("%VERSION%", globalVersion)
      exec "git commit " + opts.commitFiles.join(" ") + " -m \"" + commitMessage + "\"", (err, stdout, stderr) ->
        grunt.fatal "Can not create the commit:\n  " + stderr  if err
        grunt.log.ok "Committed as \"" + commitMessage + "\""
        next()

    # CREATE TAG
    runIf opts.createTag, ->
      tagName = opts.tagName.replace("%VERSION%", globalVersion)
      tagMessage = opts.tagMessage.replace("%VERSION%", globalVersion)
      exec "git tag -a " + tagName + " -m \"" + tagMessage + "\"", (err, stdout, stderr) ->
        grunt.fatal "Can not create the tag:\n  " + stderr  if err
        grunt.log.ok "Tagged as \"" + tagName + "\""
        next()

    # PUSH CHANGES
    runIf opts.push, ->
      exec "git push " + opts.pushTo + " && git push " + opts.pushTo + " --tags", (err, stdout, stderr) ->
        grunt.fatal "Can not push to " + opts.pushTo + ":\n  " + stderr  if err
        grunt.log.ok "Pushed to " + opts.pushTo
        next()

    # PUBLISH CHANGES TO NPM
    runIf opts.npm, ->
      opts.npmTag.replace "%VERSION%", globalVersion
      exec "npm publish --tag \"" + opts.npmTag + "\"", (err, stdout, stderr) ->
        grunt.fatal "Publishing to NPM failed:\n  " + stderr  if err
        grunt.log.ok "Published to NPM with tag:" + opts.npmTag
        next()

    next()

  # ALIASES
  grunt.registerTask "bumper-only", "Just bump version and run tasks.", (versionType) ->
    grunt.task.run("bumper:" + (versionType or "") + ":bump-only")

  grunt.registerTask "bumper-commit", "Add, commit, tag, push without incrementing the version.", "bumper::commit-only"

  grunt.registerTask "bumper-release", "Bump version, run tasks, add, commit, tag, push and publish to NPM.", (versionType) ->
    grunt.task.run "bumper:" + (versionType or "") + ":push-release"

  grunt.registerTask "bumper-publish", "Just publish to NPM.", (versionType) ->
    grunt.task.run "bumper:" + (versionType or "") + ":push-publish"
