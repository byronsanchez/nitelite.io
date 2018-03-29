root = exports ? this

Robotskirt = require('robotskirt')
hljs = require('highlight.js')

class RobotskirtPage

  @runMarkdownProcess: (config, markdown) ->
      preprocessedMarkdown = RobotskirtPage.preprocess(markdown)
      renderedHtml = RobotskirtPage.renderMarkdownIntoHtml(config, preprocessedMarkdown)
      postprocessedMarkdown = RobotskirtPage.postprocess(renderedHtml)

  @preprocess: (markdown) ->
    preprocessedMarkdown = RobotskirtPage.renderCustomTags(markdown)
    return preprocessedMarkdown

  @postprocess: (html) ->
    return html

  @renderMarkdownIntoHtml: (config, markdownContent) ->

    extensions = config.robotskirt.extensions or []
    htmlFlags = config.robotskirt.htmlFlags or []
    isSmartypantsEnabled = config.robotskirt.smart or false

    robotskirtExtensions = RobotskirtPage.convertConfigurationStringsIntoRobotskirtIDs(extensions)
    robotskirtHtmlFlags = RobotskirtPage.convertConfigurationStringsIntoRobotskirtIDs(htmlFlags)

    renderer = new Robotskirt.HtmlRenderer(robotskirtHtmlFlags)
    renderer = RobotskirtPage.defineSyntaxHighlightingForCodeBlocks(renderer, config)
    markdown = new Robotskirt.Markdown(renderer, robotskirtExtensions)
    renderedHtml = markdown.render(markdownContent)

    if isSmartypantsEnabled
      renderedHtml = Robotskirt.smartypantsHtml(renderedHtml)

    return renderedHtml

  @convertConfigurationStringsIntoRobotskirtIDs: (configurationStringObject) ->

    robotskirtIDs = []
    for v,k in configurationStringObject
      uppercaseValue = v.toUpperCase()
      robotskirtIDs[k] = Robotskirt[uppercaseValue]

    return robotskirtIDs

  @defineSyntaxHighlightingForCodeBlocks: (renderer, config) ->

    renderer.blockcode = (code, lang) ->
      options = RobotskirtPage.parseSyntaxHighlightingOptions(lang)
      # Update the language based on our custom options feature.
      lang = options['lang'] || 'text'
      options['encoding'] = 'utf-8'
      output = null
  
      options['isCode'] = true
      switch lang
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

root.fromMarkdown = (markdown) ->

  config = {
    "robotskirt": {
      "extensions": ["ext_fenced_code", "ext_no_intra_emphasis", "ext_autolink", "ext_strikethrough", "ext_lax_spacing", "ext_superscript", "ext_tables"],
      "smart": true
    }
  }
 
  return RobotskirtPage.runMarkdownProcess(config, markdown)

