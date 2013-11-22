# grunt-bumper

[![Build Status](https://travis-ci.org/weareinteractive/grunt-bumper.png?branch=master)](https://travis-ci.org/weareinteractive/grunt-bumper)
[![Dependency Status](https://gemnasium.com/weareinteractive/grunt-bumper.png)](https://gemnasium.com/weareinteractive/grunt-bumper)
[![NPM version](https://badge.fury.io/js/grunt-bumper.png)](http://badge.fury.io/js/grunt-bumper)

> Bump package version, run tasks, git tag, commit & push.
>
> This is based on [grunt-push-release](https://github.com/JonnyBGod/grunt-push-release)

## Getting Started

This plugin requires Grunt `~0.4.1`

If you haven't used [Grunt](http://gruntjs.com/) before, be sure to check out the [Getting Started](http://gruntjs.com/getting-started) guide, as it explains how to create a [Gruntfile](http://gruntjs.com/sample-gruntfile) as well as install and use Grunt plugins. Once you're familiar with that process, you may install this plugin with this command:

```shell
npm install grunt-bumper --save-dev
```

Once the plugin has been installed, it may be enabled inside your Gruntfile with this line of JavaScript:

```js
grunt.loadNpmTasks('grunt-bumper');
```

## Options

This shows all the available config options with their default values.

```
bumper:
  options:
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
```

#### files
Type `Array`
Default `['package.json']`

List of files to bump. Maybe you wanna bump 'component.json' as well ?

#### updateConfigs
Type `Array`
Default `['pkg']`

Sometimes you load the content of `package.json` into a grunt config. This will update the config property, so that even tasks running in the same grunt process see the updated value.

```
bumper:
  options:
    files:         ["package.json", "bower.json"]
    updateConfigs: ["pkg",          "bower"]

```

#### releaseBranch
Type `Boolean`
Default `false`

Define branch(es) on which it is allowed to make releases. Either define a single one as string or severals as array. This helps to not accidentially make a release on a topic branch.

```js
push: {
  releaseBranch: ['develop', 'master']
}
```

#### runTasks
Type `Boolean`
Default `true`

Do you want to run tasks after bumping the version?

#### tasks
Type `Array`
Default `['default']`

List of tasks to be executed after bumping the version and before adding/commiting the files.

#### add
Type `Boolean`
Default `true`

Do you want to `git add` files?

#### addFiles
Type `Array`
Default `['.']`

An array of files that you wanna add. You can use `['.']` to add all files.

#### commit
Type `Boolean`
Default `true`

Do you wanna commit the changes?

#### commitMessage
Type `String`
Default `'Release v%VERSION%'`

The commit message. You can use `%VERSION%` which will get replaced with the new version.

#### commitFiles
Type `Array`
Default `['-a']`

An array of files that you wanna commit. You can use `['-a']` to commit all files.

#### createTag
Type `Boolean`
Default `true`

Do you want to create a git tag?

#### tagName
Type `String`
Default `'v%VERSION%'`

The tag name. You can use `%VERSION%` which will get replaced with the new version.

#### tagMessage
Type `String`
Default `'Version v%VERSION%'`

The tag message. You can use `%VERSION%` which will get replaced with the new version.

#### push
Type `Boolean`
Default `true`

Do you want to push all these changes?

#### pushTo
Type `String`
Default `'origin'`

Name of the remote branch to push to.

#### npm
Type `Boolean`
Default `false`

Do you wanna publish all these changes to NPM?

Make sure you have registered an npm used: 'npm adduser'

#### npmTag
Type `String`
Default `'Release v%VERSION%'`

The name of the tag. You can use `%VERSION%` which will get replaced with the new version.

## Example Usage

Let's say current version is `0.0.1`.

````
$ grunt bumper
>> Version bumped to 0.0.2
>> Committed as "Release v0.0.2"
>> Tagged as "v0.0.2"
>> Pushed to origin

$ grunt bumper:patch
>> Version bumped to 0.0.3
>> Committed as "Release v0.0.3"
>> Tagged as "v0.0.3"
>> Pushed to origin

$ grunt bumper:minor
>> Version bumped to 0.1.0
>> Committed as "Release v0.1.0"
>> Tagged as "v0.1.0"
>> Pushed to origin

$ grunt bumper:major
>> Version bumped to 1.0.0
>> Committed as "Release v1.0.0"
>> Tagged as "v1.0.0"
>> Pushed to origin

$ grunt bumper:git
>> Version bumped to 1.0.0-1-ge96c
>> Committed as "Release v1.0.0-1-ge96c"
>> Tagged as "v1.0.0-1-ge96c"
>> Pushed to origin
````

You can use `bump-only` and `bump-commit` to call each step separately.

```bash
$ grunt bumper-only:minor
$ grunt bumper-commit
$ grunt bumper-release //This will do a full push and publish to npm even if you have configured npm option to false
$ grunt bumper-publish //Just publishes to NPM overriding (npm option: false)
```

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## License
Copyright (c) We Are Interactive under the MIT license.
