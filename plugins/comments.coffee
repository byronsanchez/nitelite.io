_ = require "underscore"
path = require 'path'

module.exports = (env, callback) ->

  class CommentsPlugin
    ### A page has a number and a list of articles ###
    #
    # Calculate related posts.
    # Returns [<Post>]
    generate_comments: (contents) ->
      articles = env.helpers.getArticles(contents)
      return null unless Object.keys(articles).length > 0
      return null unless contents.comments

      for article in articles
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

        if _.has(contents.comments, comment_dir)
          article.comments = {}
          for comment in _.keys(contents.comments[comment_dir]).sort()
            key = comment
            comment = contents.comments[comment_dir][comment]
            article.comments[key] = comment

  generate_comments = (contents) ->
    if contents
      c = new CommentsPlugin()
      c.generate_comments(contents)

  env.registerGenerator 'comments', (contents, callback) ->
    generate_comments(contents)
    callback null

  callback()

