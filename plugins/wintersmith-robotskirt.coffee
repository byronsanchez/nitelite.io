async = require 'async'
# Robotskirt = require 'robotskirt'
fs = require 'fs'
hljs = require 'highlight.js'

module.exports = (env, callback) ->

  class RobotskirtPage extends env.plugins.MarkdownPage

    # a post or page is a draft is published is not explictly enabled
    isDraft: ->
      if @metadata
        if @metadata["published"]
          return true if @metadata["published"] != "1" && @metadata["published"] != 1
        else
          return true
      else
        return false

    # Method written by Luke Hagan (lukehagan.com)
    # Licensed under the MIT license
    # https://github.com/lhagan/wintersmith-showdown/blob/master/plugin.coffee
    # Commit ID: 24cb3539b23d3749cfcad90012f1d98d544d9868
    getHtml: (base=env.config.baseUrl) ->
      # TODO: cleaner way to achieve this?
      # http://stackoverflow.com/a/4890350
      name = @getFilename()
      name = name[name.lastIndexOf('/')+1..]
      loc = @getLocation(base)
      fullName = if name is 'index.html' then loc else loc + name
      # handle links to anchors within the page
      @_html = @_htmlraw.replace(/(<(a|img)[^>]+(href|src)=")(#[^"]+)/g, '$1' + fullName + '$4')
      # handle relative links
      @_html = @_html.replace(/(<(a|img)[^>]+(href|src)=")(?!http|\/)([^"]+)/g, '$1' + loc + '$4')
      # handles non-relative links within the site (e.g. /about)
      if base
        @_html = @_html.replace(/(<(a|img)[^>]+(href|src)=")\/([^"]+)/g, '$1' + base + '$4')
      return @_html

    getView: ->
      return 'none' if @isDraft()
      return super()

    getIntro: (base) ->
      html = @getHtml(base)
      cutoffs = ['<!--more-->', '<span class="more']
      idx = Infinity
      for cutoff in cutoffs
        i = html.indexOf cutoff
        if i isnt -1 and i < idx
          idx = i
      if idx isnt Infinity
        return html.substr 0, idx
      else
        return html

    @property 'hasMore', ->
      @_html ?= @getHtml()
      @_intro ?= @getIntro()
      @_hasMore ?= (@_html.length > @_intro.length)
      return @_hasMore

    @runHtmlProcess: (config, markdown) ->
        preprocessedMarkdown = RobotskirtPage.preprocess(markdown)
        renderedHtml = RobotskirtPage.renderHtmlIntoHtml(config, preprocessedMarkdown)
        postprocessedMarkdown = RobotskirtPage.postprocess(renderedHtml)

    @runMarkdownProcess: (config, markdown) ->
        # preprocessedMarkdown = RobotskirtPage.preprocess(markdown)
        # renderedHtml = RobotskirtPage.renderMarkdownIntoHtml(config, preprocessedMarkdown)
        # postprocessedMarkdown = RobotskirtPage.postprocess(renderedHtml)

        preprocessedMarkdown = RobotskirtPage.preprocess(markdown)
        renderedHtml = RobotskirtPage.renderHtmlIntoHtml(config, preprocessedMarkdown)
        postprocessedMarkdown = RobotskirtPage.postprocess(renderedHtml)

    @preprocess: (markdown) ->
      preprocessedMarkdown = RobotskirtPage.renderCustomTags(markdown)
      return preprocessedMarkdown

    @postprocess: (html) ->
      return html

    @renderHtmlIntoHtml: (config, markdownContent) ->
      renderedHtml = markdownContent
      return renderedHtml

    # @renderMarkdownIntoHtml: (config, markdownContent) ->
    #
    #   extensions = config.robotskirt.extensions or []
    #   htmlFlags = config.robotskirt.htmlFlags or []
    #   isSmartypantsEnabled = config.robotskirt.smart or false
    #
    #   robotskirtExtensions = RobotskirtPage.convertConfigurationStringsIntoRobotskirtIDs(extensions)
    #   robotskirtHtmlFlags = RobotskirtPage.convertConfigurationStringsIntoRobotskirtIDs(htmlFlags)
    #
    #   renderer = new Robotskirt.HtmlRenderer(robotskirtHtmlFlags)
    #   renderer = RobotskirtPage.defineSyntaxHighlightingForCodeBlocks(renderer, config)
    #   markdown = new Robotskirt.Markdown(renderer, robotskirtExtensions)
    #   renderedHtml = markdown.render(markdownContent)
    #
    #   if isSmartypantsEnabled
    #     renderedHtml = Robotskirt.smartypantsHtml(renderedHtml)
    #
    #   return renderedHtml

    # @convertConfigurationStringsIntoRobotskirtIDs: (configurationStringObject) ->
    #
    #   robotskirtIDs = []
    #   for v,k in configurationStringObject
    #     uppercaseValue = v.toUpperCase()
    #     robotskirtIDs[k] = Robotskirt[uppercaseValue]
    #
    #   return robotskirtIDs

    @defineSyntaxHighlightingForCodeBlocks: (renderer, config) ->

      renderer.blockcode = (code, lang) ->
        options = RobotskirtPage.parseSyntaxHighlightingOptions(lang)
        # Update the language based on our custom options feature.
        lang = options['lang'] || 'text'
        options['encoding'] = 'utf-8'
        output = null

        options['isCode'] = true
        switch lang
          # dream
          when 'd'
            options.isCode = false
          when 'hh'
            options.isCode = false
          when 'ld'
            options.isCode = false
          when 'fa'
            options.isCode = false
          when 'nd'
            options.isCode = false
          # pickup
          when 'out'
            options.isCode = false
          when 'in'
            options.isCode = false
          when 'sa'
            options.isCode = false
          when 't'
            options.isCode = false

        if options.isCode
          output = RobotskirtPage.highlightCode(code, options, lang)
          RobotskirtPage.addCodeTags(output, lang)
        else
          # Run it through the markdown process; otherwise, the raw markdown
          # will be output since this was flagged as a codeblock by the robotskirt
          output = RobotskirtPage.runMarkdownProcess(config, code)
          RobotskirtPage.addHighlightTags(output, options, lang)

      return renderer

    @highlightCode: (code, options, lang) ->
      if lang == 'text'
        return code
      else
        try
          lang = 'cpp' if lang is 'c'
          highlightedCode = hljs.highlight(lang, code).value
          return highlightedCode
        catch error
          return code

    @parseSyntaxHighlightingOptions: (lang) ->
      # Set default options
      options = {
        "lang": "text"
      }

      # First split each key-value pair from one another
      if lang
        values = lang.split('|')
        # Next split each key value pair and override defaults if necessary.
        for v, index in values

          # This should only iterate once if the options were not malformed
          # when they were passed
          for key, value in v.split('=')

            # First key must always be the language
            if index == 0
              if !value
                value = key
                key = "lang"
            else
              # If the value was not defined, handle it
              if !value
                value = true

            options[key] = value

      return options

    @renderCustomTags: (markdown) ->
      # Video tags.
      # Only replace if there's at least one match. This is why scanning
      # happens first.
      syntax = /\[video\s+?(.*?)(?:\s+?\|\s+?(.*?))?\]/m
      matches = markdown.match(syntax)

      while ((matches = syntax.exec(markdown)) != null)

        if matches
          match_string = matches[0]
          source = matches[1]
          style = matches[2]

          if !style
            style = ''
          else
            style = ' ' + style

          # Youtube Regex
          syntax_youtube = /(?:https?:\/\/)?(?:www\.)?youtu(?:\.be|be\.com)\/(?:(?:watch\?v=)|(?:embed\/))?([\w\-]{10,})/m
          source_matches = source.match(syntax_youtube)
          id = source_matches[1]

          if id
            # Match only the particular tag we are working on. This is
            # because there may be multiple video tags per page.
            markdown = markdown.replace(match_string, '<div class="flex-video' + style + '"><iframe width="560" height="315" src="//www.youtube.com/embed/' + id + '" frameborder="0" allowfullscreen></iframe></div>')

      return markdown

    @addCodeTags: (code, lang) ->
      return '<div class="highlight ' + lang + '"><pre><code class="'+lang+'">' + code + '</code></pre></div>'

    @addHighlightTags: (text, options, lang) ->
      return '<div class="text-highlight ' + lang + '">' + text + '</div>'

  RobotskirtPage.fromFile = (filepath, callback) ->

    console.log "MARK DOW NFILE"

    async.waterfall [
      (callback) ->
        fs.readFile filepath.full, callback
      (buffer, callback) ->
        RobotskirtPage.extractMetadata buffer.toString(), callback
      (result, callback) =>
        {markdown, metadata} = result
        page = new this filepath, metadata, markdown
        callback null, page
      (page, callback) =>
        page._htmlraw = RobotskirtPage.runMarkdownProcess(env.config, page.markdown)
        callback null, page
      (page, callback) =>
        callback null, page
    ], callback

  class HtmlPage extends RobotskirtPage

  HtmlPage.fromFile = (filepath, callback) ->

    console.log "HTM LFILE"

    async.waterfall [
      (callback) ->
        fs.readFile filepath.full, callback
      (buffer, callback) ->
        HtmlPage.extractMetadata buffer.toString(), callback
      (result, callback) =>
        {markdown, metadata} = result
        page = new this filepath, metadata, markdown
        callback null, page
      (page, callback) =>
        page._htmlraw = RobotskirtPage.runHtmlProcess(env.config, page.markdown)
        page._htmlraw = page.markdown
        callback null, page
      (page, callback) =>
        callback null, page
    ], callback

  env.registerContentPlugin 'pages', '**/*.*(markdown|mkd|md)', RobotskirtPage
  env.registerContentPlugin 'pages', '**/*.html', HtmlPage

  env.helpers.RobotskirtPage = RobotskirtPage
  env.helpers.HtmlPage = HtmlPage

  callback()
