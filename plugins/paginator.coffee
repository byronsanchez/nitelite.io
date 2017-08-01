
module.exports = (env, callback) ->
  ### Paginator plugin. Defaults can be overridden in config.json
      e.g. "paginator": {"perPage": 10} ###

  defaults =
    template: 'index.jade' # template that renders pages
    articles: 'articles' # directory containing contents to paginate
    first: 'index.html' # filename/url for first page
    filename: 'page/%d/index.html' # filename for rest of pages
    perPage: 2 # number of articles per page
    isEnabled: 1

  # assign defaults any option not set in the config file
  options = env.config.paginator or {}
  for key, value of defaults
    options[key] ?= defaults[key]

  getArticles = (contents) ->
    # helper that returns a list of articles found in *contents*
    articles = []
    for page_key, page_value of contents["notebooks"]
      if page_value["metadata"]
        articles.push page_value if page_value instanceof env.plugins.Page && (page_value["metadata"]["published"] == "1" || page_value["metadata"]["published"] == 1)

    articles.sort (a, b) -> b.date - a.date
    return articles

  class PaginatorPage extends env.plugins.Page
    ### A page has a number and a list of articles ###

    constructor: (@pageNum, @articles) ->

    getFilename: ->
      if @pageNum is 1
        options.first
      else
        options.filename.replace '%d', @pageNum

    getView: -> (env, locals, contents, templates, callback) ->
      # simple view to pass articles and pagenum to the paginator template
      # note that this function returns a funciton
    
      # remove unpublished articles

      # get the pagination template
      template = templates[options.template]
      if not template?
        return callback new Error "unknown paginator template '#{ options.template }'"

      # setup the template context
      if @articles
        ctx = {@articles, @prevPage, @nextPage}
      else
        ctx = {@prevPage, @nextPage}

      # extend the template context with the enviroment locals
      env.utils.extend ctx, locals

      # finally render the template
      template.render ctx, callback

    @createObjectContainingAllPaginatorPages = (articles, options) ->

      pages = []
      # populate pages
      if options.isEnabled
        numPages = Math.ceil articles.length / options.perPage
        for i in [0...numPages]
          pageArticles = articles.slice i * options.perPage, (i + 1) * options.perPage
          pages.push new PaginatorPage i + 1, pageArticles
      else
        pageArticles = articles.slice i * options.perPage, options.perPage
        pages.push new PaginatorPage 1, pageArticles

      # add references to prev/next to each page
      for page, i in pages
        page.prevPage = pages[i - 1]
        page.nextPage = pages[i + 1]

      return pages

    @createObjectToBeMergedWithContentTree = (pages) ->

      # create the object that will be merged with the content tree (contents)
      # do _not_ modify the tree directly inside a generator, consider it read-only
      rv = {pages:{}}

      # If there are no articles available for the index, create a default page
      # for the index so potential links don't break.
      if !pages || pages.length < 1
        rv.pages["index.page"] = new PaginatorPage 1, null
      # Else pass the content index to the page
      else
        for page in pages
          rv.pages["#{ page.pageNum }.page"] = page # file extension is arbitrary
        rv['index.page'] = pages[0] # alias for first page
      return rv


  # register a generator, 'paginator' here is the content group generated content will belong to
  # i.e. contents._.paginator
  env.registerGenerator 'paginator', (contents, callback) ->
    # find all articles
    articles = getArticles contents

    pages = PaginatorPage.createObjectContainingAllPaginatorPages(articles, options)
    rv = PaginatorPage.createObjectToBeMergedWithContentTree(pages)

    # callback with the generated contents
    callback null, rv

  # add the article helper to the environment so we can use it later
  env.helpers.getArticles = getArticles

  # tell the plugin manager we are done
  callback()
