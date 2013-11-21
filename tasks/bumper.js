/*
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
*/

var exec, semver;

semver = require("semver");
exec = require("child_process").exec;

module.exports = function(grunt) {
  "use strict";
  grunt.registerTask("bumper", "Bump package version, run tasks, git tag, commit & push.", function(versionType, incOrCommitOnly) {
    var VERSION_REGEXP, done, gitVersion, globalVersion, next, opts, queue, runIf;
    opts = this.options({
      bumpVersion: true,
      files: ["package.json"],
      updateConfigs: ['pkg'],
      releaseBranch: false,
      runTasks: true,
      tasks: ["default"],
      add: true,
      addFiles: ["."],
      commit: true,
      commitMessage: "Release v%VERSION%",
      commitFiles: ["-a"],
      createTag: true,
      tagName: "v%VERSION%",
      tagMessage: "Version %VERSION%",
      push: true,
      pushTo: "origin",
      npm: false,
      npmTag: "Release v%VERSION%",
      gitDescribeOptions: "--tags --always --abbrev=1 --dirty=-d"
    });
    if (incOrCommitOnly === "bump-only") {
      grunt.verbose.writeln("Only incrementing the version.");
      opts.add = false;
      opts.commit = false;
      opts.createTag = false;
      opts.push = false;
    }
    if (incOrCommitOnly === "commit-only") {
      grunt.verbose.writeln("Only commiting/tagging/pushing.");
      opts.bumpVersion = false;
    }
    if (incOrCommitOnly === "push-release") {
      grunt.verbose.writeln("Pushing and publishing to NPM.");
      opts.npm = true;
    } else {
      opts.npm = false;
    }
    if (incOrCommitOnly === "push-publish") {
      grunt.verbose.writeln("Publishing to NPM.");
      opts.bumpVersion = false;
      opts.runTasks = false;
      opts.add = false;
      opts.commit = false;
      opts.createTag = false;
      opts.push = false;
      opts.npm = true;
    }
    done = this.async();
    queue = [];
    next = function() {
      if (!queue.length) {
        return done();
      }
      return queue.shift()();
    };
    runIf = function(condition, behavior) {
      if (condition) {
        return queue.push(behavior);
      }
    };
    runIf(opts.releaseBranch, function() {
      if (opts.npm || opts.commit || opts.push) {
        return exec("git rev-parse --abbrev-ref HEAD", function(err, stdout, stderr) {
          var currentBranch, rBranches;
          if (err || stderr) {
            grunt.fatal("Cannot determine current branch.");
          }
          currentBranch = stdout.trim();
          rBranches = (typeof opts.releaseBranch === "string" ? [opts.releaseBranch] : opts.releaseBranch);
          rBranches.forEach(function(rBranch) {
            if (rBranch === currentBranch) {
              return next();
            }
          });
          grunt.warn("The current branch is not in the list of release branches.");
          return next();
        });
      }
    });
    globalVersion = void 0;
    gitVersion = void 0;
    VERSION_REGEXP = /(\bversion[\'\"]?\s*[:=]\s*[\'\"])([\da-z\.-]+)([\'\"])/i;
    runIf(opts.bumpVersion && versionType === "git", function() {
      return exec("git describe " + opts.gitDescribeOptions, function(err, stdout, stderr) {
        if (err) {
          grunt.fatal("Can not get a version number using `git describe`");
        }
        gitVersion = stdout.trim();
        return next();
      });
    });
    runIf(opts.bumpVersion, function() {
      opts.files.forEach(function(file, idx) {
        var cfg, configProperty, content, version;
        version = null;
        content = grunt.file.read(file).replace(VERSION_REGEXP, function(match, prefix, parsedVersion, suffix) {
          version = gitVersion || semver.inc(parsedVersion, versionType || "patch");
          return prefix + version + suffix;
        });
        if (!version) {
          grunt.fatal("Can not find a version to bump in " + file);
        }
        grunt.file.write(file, content);
        grunt.log.ok("Version bumped to " + version + (opts.files.length > 1 ? " (in " + file + ")" : ""));
        if (!globalVersion) {
          globalVersion = version;
        } else {
          if (globalVersion !== version) {
            grunt.warn("Bumping multiple files with different versions!");
          }
        }
        configProperty = opts.updateConfigs[idx];
        if (!configProperty) {
          return;
        }
        cfg = grunt.config(configProperty);
        if (!cfg) {
          return grunt.warn("Can not update \"" + configProperty + "\" config, it does not exist!");
        }
        cfg.version = version;
        grunt.config(configProperty, cfg);
        return grunt.log.ok("" + configProperty + "'s version updated");
      });
      return next();
    });
    runIf(opts.runTasks, function() {
      grunt.task.run(opts.tasks);
      return next();
    });
    runIf(!opts.bumpVersion, function() {
      if (opts.updateConfigs.length) {
        globalVersion = grunt.config(opts.updateConfigs[0]).version;
      } else {
        globalVersion = grunt.file.readJSON(opts.files[0]).version;
      }
      return next();
    });
    runIf(opts.add, function() {
      return exec("git add " + opts.addFiles.join(" "), function(err, stdout, stderr) {
        if (err) {
          grunt.fatal("Can not add files:\n  " + stderr);
        }
        grunt.log.ok("Added files: \"" + opts.addFiles.join(" ") + "\"");
        return next();
      });
    });
    runIf(opts.commit, function() {
      var commitMessage;
      commitMessage = opts.commitMessage.replace("%VERSION%", globalVersion);
      return exec("git commit " + opts.commitFiles.join(" ") + " -m \"" + commitMessage + "\"", function(err, stdout, stderr) {
        if (err) {
          grunt.fatal("Can not create the commit:\n  " + stderr);
        }
        grunt.log.ok("Committed as \"" + commitMessage + "\"");
        return next();
      });
    });
    runIf(opts.createTag, function() {
      var tagMessage, tagName;
      tagName = opts.tagName.replace("%VERSION%", globalVersion);
      tagMessage = opts.tagMessage.replace("%VERSION%", globalVersion);
      return exec("git tag -a " + tagName + " -m \"" + tagMessage + "\"", function(err, stdout, stderr) {
        if (err) {
          grunt.fatal("Can not create the tag:\n  " + stderr);
        }
        grunt.log.ok("Tagged as \"" + tagName + "\"");
        return next();
      });
    });
    runIf(opts.push, function() {
      return exec("git push " + opts.pushTo + " && git push " + opts.pushTo + " --tags", function(err, stdout, stderr) {
        if (err) {
          grunt.fatal("Can not push to " + opts.pushTo + ":\n  " + stderr);
        }
        grunt.log.ok("Pushed to " + opts.pushTo);
        return next();
      });
    });
    runIf(opts.npm, function() {
      opts.npmTag.replace("%VERSION%", globalVersion);
      return exec("npm publish --tag \"" + opts.npmTag + "\"", function(err, stdout, stderr) {
        if (err) {
          grunt.fatal("Publishing to NPM failed:\n  " + stderr);
        }
        grunt.log.ok("Published to NPM with tag:" + opts.npmTag);
        return next();
      });
    });
    return next();
  });
  grunt.registerTask("bumper-only", "Just bump version and run tasks.", function(versionType) {
    return grunt.task.run("bumper:" + (versionType || "") + ":bump-only");
  });
  grunt.registerTask("bumper-commit", "Add, commit, tag, push without incrementing the version.", "bumper::commit-only");
  grunt.registerTask("bumper-release", "Bump version, run tasks, add, commit, tag, push and publish to NPM.", function(versionType) {
    return grunt.task.run("bumper:" + (versionType || "") + ":push-release");
  });
  return grunt.registerTask("bumper-publish", "Just publish to NPM.", function(versionType) {
    return grunt.task.run("bumper:" + (versionType || "") + ":push-publish");
  });
};
