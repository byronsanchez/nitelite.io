# wintersmith-webpack-babel
# Copyright (c) 2016 Chris Peters
# Licensed under the MIT License
# Original source repo: https://github.com/bildepunkt/wintersmith-webpack-babel
# I modified it to fit my own use case, but you can get the original sources at the above link.
#
# Description:
#
# Passes each matching file (ie. main.coffee entrypoint file) to webpack to compile
#
# Basically, you use "wintersmith build" and during wintersmith's compile process, wintersmith will call out to webpack
# and compile anything that needs to be compiled.

fs = require 'fs'
xpile = require './xpile'

module.exports = (env, callback) ->
    config = env.config.webpack || {}
    if config.pattern?
            pattern = config.pattern
            delete config.pattern

    class WebpackPlugin extends env.ContentPlugin

        constructor: (@filepath) ->

        getFilename: ->
            @filepath.relative

        getView: -> (env, locals, contents, templates, callback) ->
            xpile @filepath, config.output, (result) ->
                callback null, new Buffer(result)

    WebpackPlugin.fromFile = (filepath, callback) ->
        fs.readFile filepath.full, (error, result) ->
            if not error?
                plugin = new WebpackPlugin filepath

            callback error, plugin

    env.registerContentPlugin 'scripts', pattern || '**/main.*(es|es6|jsx|coffee)', WebpackPlugin

    callback()
