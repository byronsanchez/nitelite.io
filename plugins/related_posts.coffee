
module.exports = (env, callback) ->
  
  class RelatedPostsPlugin
    ### A page has a number and a list of articles ###
    #
    # Calculate related posts.
    # Returns [<Post>]
    related_posts: (current_post, posts) ->
      return null unless Object.keys(posts).length > 1
      tag_hash = @tag_freq(posts)
      highest_freq = Math.max.apply(Object.keys(tag_hash).map((v) -> return tag_hash[v]))
      related_scores = {}
      post_table = {}

      # key is used as a local identifier for posts. we can't key with the post object
      # for the related_scores array
      for post, key in posts
        post_table[key] = post
        post.metadata.tags ||= []

        for tag in post.metadata.tags
          if current_post.metadata.tags.indexOf(tag) > -1 && post != current_post
            cat_freq = @tag_freq(posts)
            cat_freq = cat_freq[tag]

            # Initialize the element if it doesn't already exist.
            if !related_scores[key]
              related_scores[key] = 0

            related_scores[key] += (1+highest_freq-cat_freq)

      # If there are no related posts, output nil so that the 
      # object can be used as part of an if check in templates.
      output = @sort_related_posts(related_scores, post_table)
      if Object.keys(output).length < 1
        return null
      else
        return output

    # Calculate the frequency of each tag.
    # Returns {tag => freq, tag => freq, ...}
    tag_freq: (posts) ->
      return @tag_freq_array if @tag_freq_array
      @tag_freq_array = {}
      for post in posts
        post.metadata.tags ||= []
        for tag in post.metadata.tags
          if !@tag_freq_array[tag]
            @tag_freq_array[tag] = 0
          @tag_freq_array[tag] += 1
      return @tag_freq_array

    # Sort the related posts in order of their score and date
    # and return just the posts
    sort_related_posts: (related_scores, post_table) ->
      keys = Object.keys(related_scores)

      sorted_related_scores = keys.sort (a, b) ->
        if related_scores[a] < related_scores[b]
          return 1
        else if related_scores[a] > related_scores[b]
          return -1
        else
          if post_table[b].metadata.date < post_table[a].metadata.date
            return -1
          else if post_table[b].metadata.date == post_table[a].metadata.date
            return 0
          else if post_table[b].metadata.date > post_table[a].metadata.date
            return 1

      result = sorted_related_scores.map((v) -> return post_table[v])
      return result

  related_posts = (article, articles) ->
    if article
      rp = new RelatedPostsPlugin()
      return rp.related_posts(article, articles)
    else
      return null

  env.registerGenerator 'related_posts', (contents, callback) ->
    if contents
      articles = env.helpers.getArticles contents
      for article in articles
        article.related_articles = related_posts(article, articles)
    callback null

  callback()

