fs = require 'fs'
path = require 'path'

module.exports = (env, callback) ->

  class HtmlPlugin extends env.ContentPlugin

    constructor: (@_filepath, @_text) ->


    getFilename: ->
      @_filepath.relative

    getView: ->
      (env, locals, contents, templates, callback) ->
        # return the plain HTML file
        callback null, new Buffer @_text

  HtmlPlugin.fromFile = (filepath, callback) ->
    fs.readFile filepath.full, (error, buffer) ->
      if error
        callback error
      else
        callback null, new HtmlPlugin filepath, buffer.toString()
        
  env.registerContentPlugin 'html', '**/*.html', HtmlPlugin
  callback() # tell the plugin manager we are done
