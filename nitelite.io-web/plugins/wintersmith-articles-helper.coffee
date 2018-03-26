
module.exports = (env, callback) ->
  options = null
  defaults =
    articles: 'articles' # directory containing contents to paginate

  updateOptions = () ->
    options = env.config.articlesHelper or {}
    for key, value of defaults
      options[key] ?= defaults[key]

  if !env.helpers.getArticles

    env.helpers.getArticles = (contents) ->
      # helper that returns a list of articles found in *contents*
      articles = []
      for page_key, page_value of contents["notebooks"]
        if page_value["metadata"]
          articles.push page_value if page_value instanceof env.plugins.Page && (page_value["metadata"]["published"] == "1" || page_value["metadata"]["published"] == 1)

      articles.sort (a, b) -> b.date - a.date
      return articles

  updateOptions()

  callback()

