bootstrap = require '../bootstrap.coffee'
env = bootstrap.env
config = bootstrap.env.config

comments = require(config['support']).comments

module.exports = (grunt) ->
  grunt.registerTask('comments-pull', 'Pull the comments database from the server', () ->
    comments.pullCommentsDatabase(config)
  )

  grunt.registerTask('comments-push', 'Push the comments database to the server', () ->
    comments.pushCommentsDatabase(config)
  )

  grunt.registerTask('comments-generate', 'Create the comments directory and populate it with comments from the database', () ->
    done = this.async()
    comments.generateCommentsFromDatabase(config, done)
  )

  grunt.registerTask('comments-list', 'List all comments', () ->
    done = this.async()
    comments.listComments(config, done)
  )

  grunt.registerTask('comments-view', 'Display the specified comment', (id) ->
    done = this.async()
    comments.viewComment(config, id, done)
  )

  grunt.registerTask('comments-delete', 'Permanently delete the specified comment from the database', (id) ->
    done = this.async()
    comments.deleteComment(config, id, done)
  )

  grunt.registerTask('comments-publish', "Publish the specified comment", (id) ->
    done = this.async()
    comments.publishComment(config, id, done)
  )

  grunt.registerTask('comments-unpublish', "Unpublish the specified comment", (id) ->
    done = this.async()
    comments.unpublishComment(config, id, done)
  )

  grunt.registerTask('comments-merge', 'Resume the building of a merge database after a conflict has manually been resolved', () ->
    db_path = "#{config['database_output']}/#{config['database_scripts']['comments']}"
    local_db = "#{db_path}"
    backup_db = "#{db_path}.backup"
    server_db = "#{db_path}.pre_push_check"
    comments.buildMergedDatabase(config, local_db, backup_db, server_db)
  )

