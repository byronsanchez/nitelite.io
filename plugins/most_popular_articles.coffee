_ = require "underscore"
path = require 'path'
fs = require 'fs'
glob =  require 'glob'

module.exports = (env, callback) ->

  defaults =
    limit: 5 # max number of articles to display

  # assign defaults any option not set in the config file
  options = env.config.most_popular_articles or {}
  for key, value of defaults
    options[key] ?= defaults[key]

  class MostPopularArticlesPlugin
    getKeyFromValue: (object, value) ->
      for prop in object
        if object.hasOwnProperty(prop)
           if object[prop] == value
             return prop


    ### A page has a number and a list of articles ###
    #
    # Calculate most popular articles.
    # Returns [<Post>]
    most_popular_articles: (contents) ->
      articles = env.helpers.getArticles(contents)
      return null unless Object.keys(articles).length > 0
      return null unless contents.comments

      most_popular_articles = []
      article_dir_table = {}
      for article, i in articles
        filepath = article.filepath.relative
        basename = path.basename(filepath, "." + env.config['post_ext'])

        # Remove the notebooks/ dir portion
        notebook_dir = filepath.substring(filepath.indexOf('/') + 1)
        pieces = notebook_dir.split("/")
        skill = pieces[0]
        notebook = pieces[1]
        notebook_entry_with_ext = pieces[2]
        notebook_entry = basename

        # location of comments for a notebook_entry
        #comment_dir = "#{skill}-#{notebook}-#{notebook_entry}"

        comment_dir = "#{notebook_entry}"

        # TODO: make comments dir configurable
        if fs.existsSync("./contents/comments/#{comment_dir}")
          files = glob.sync(path.join("./contents/comments/#{comment_dir}",  "/*.#{env.config['comment_ext']}"))

          most_popular_articles[i] = comment_dir
          # Needed to make url available to template after sorting
          article_dir_table[comment_dir] = contents.notebooks[skill][notebook][notebook_entry_with_ext]

      most_popular_articles = @sort_most_popular_articles(most_popular_articles, contents)

      output = {}
      for p, i in most_popular_articles
        entry = article_dir_table[p]
        if i >= options.limit
          break
        if entry
          title = entry.metadata.title
          output[title] = entry.url

      if Object.keys(output).length < 1
        return null
      else
        return output

    sort_most_popular_articles: (most_popular_articles, contents) ->
      result = most_popular_articles.sort( (a, b) ->
        if _.has(contents.comments, a) && _.has(contents.comments, b)
          _.keys(contents.comments[b]).length - _.keys(contents.comments[a]).length
        else if _.has(contents.comments, a)
          return -1
        else if _.has(contents.comments, b)
          return 1
        else
          return 0
      )

      return result

  most_popular_articles = (contents) ->
    if contents
      mp = new MostPopularArticlesPlugin()
      mp.most_popular_articles(contents)

  env.registerGenerator 'most_popular_articles', (contents, callback) ->
    # register articles to be accessible by templates
    env.locals.most_popular_articles = most_popular_articles(contents)
    callback null

  callback()

