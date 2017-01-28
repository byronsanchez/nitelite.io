root = exports ? this

async = require 'async'
util = require 'util'
sh = require 'execSync'
fs = require 'fs'
mkdirp = require 'mkdirp'
path = require 'path'
colors = require 'colors'
glob = require 'glob'
yaml = require('js-yaml')
sqlite3 = require('sqlite3').verbose()
crypto = require 'crypto'

createCommentsDatabase = () ->
  console.log "Comments database could not be retrieved from server".red

  # TODO: create database locally (ask yes or no)

createBackupDatabase = (config) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")
    # Make a backup for comparisons in case there are changes to the server
    # database while modifying the local db.
    console.log "Creating database backup..."
    code = sh.run "cp #{config['database_output']}/#{config['database_scripts']['comments']} #{config['database_output']}/#{config['database_scripts']['comments']}.backup"
  else
    console.log "Comments database does not exist".red

root.pullCommentsDatabase = (config) ->
  console.log "Pulling comments from database..."

  code = sh.run "rsync -zptlr --progress --delete --rsh='ssh -p#{config['deployment']['remote_port']}' #{config['deployment']['connection_production']}:#{config['deployment']['remote_database_output']}/#{config['database_scripts']['comments']} #{config['database_output']}/#{config['database_scripts']['comments']}"

  if code != 0
    #createCommentsDatabase()
    console.log "Comments database could not be pulled".red
  else
    createBackupDatabase(config)
    console.log "Comments database pulled successfully".green

root.pushCommentsDatabase = (config) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")

    local_db = "#{config['database_output']}/#{config['database_scripts']['comments']}"
    backup_db = "#{config['database_output']}/#{config['database_scripts']['comments']}.backup"
    pre_push_db = "#{config['database_output']}/#{config['database_scripts']['comments']}.pre_push_check"
    server_db = "#{config['deployment']['connection_production']}:#{config['deployment']['remote_database_output']}/#{config['database_scripts']['comments']}"

    console.log "Checking server database for new comments that may have been submitted during local modifications..."
    code = sh.run "rsync -zptlr --progress --delete --rsh='ssh -p#{config['deployment']['remote_port']}' #{server_db} #{pre_push_db}"

    code = sh.run "cmp #{backup_db} #{pre_push_db}"

    if code == 0
      # Clean up the pre_push db
      code = sh.run "rm #{pre_push_db}"

      console.log "No new comments were submitted to the server database."
      console.log "Pushing locally modified comments database to server..."

      code = sh.run "rsync -zptlr --progress --delete --rsh='ssh -p#{config['deployment']['remote_port']}' #{local_db} #{server_db}"
      if code != 0
        #createCommentsDatabase()
        console.log "Comments database could not be pushed".red
      else
        # Update the backup since the server has been updated.
        createBackupDatabase(config)
        console.log "Comments database pushed successfully".green
    else if code == 1
      console.log "New comments were submitted to the server database while the local copy was being modified"
      # mergedb will take care of removing pre_push_db when its done using it
      mergeDatabases(config, local_db, backup_db, pre_push_db)
    else
      # Clean up the pre_push db
      code = sh.run "rm #{pre_push_db}"
      console.log "Error during comparison!".red
  else
    console.log "Comments database does not exist".red

mergeDatabases = (config, local_db, backup_db, server_db) ->
  local_sql = "#{config['assets']}/comments_local_changes.sql"
  backup_sql = "#{config['assets']}/comments_backup.sql"
  server_sql = "#{config['assets']}/comments_server_changes.sql"
  merged_sql = "#{config['assets']}/comments_merged_changes.sql"
  merged_db = "#{config['assets']}/comments_merged_changes.db"

  console.log "Merging server updates with local changes..."
  code = sh.run "sqlite3 #{local_db} .dump > #{local_sql}"
  code = sh.run "sqlite3 #{backup_db} .dump > #{backup_sql}"
  code = sh.run "sqlite3 #{server_db} .dump > #{server_sql}"
  code = sh.run "merge -p #{local_sql} #{backup_sql} #{server_sql} > #{merged_sql}"

  if code == 0
    buildMergedDatabase(config, local_db, backup_db, server_db)
  else if code == 1
    console.log "There were merge conflicts. Please do the following:".yellow
    console.log "- Resolve the conflicts in #{merged_sql}".yellow
    console.log "- Run 'rake comments-merge'".yellow
    process.exit()
  else
    console.log "Problems encountered during merge...".red

root.buildMergedDatabase = (config, local_db, backup_db, server_db) ->
  local_sql = "#{config['assets']}/comments_local_changes.sql"
  backup_sql = "#{config['assets']}/comments_backup.sql"
  server_sql = "#{config['assets']}/comments_server_changes.sql"
  merged_sql = "#{config['assets']}/comments_merged_changes.sql"
  merged_db = "#{config['assets']}/comments_merged_changes.db"

  code = sh.run "sqlite3 #{merged_db} < #{merged_sql}"
  code = sh.run "rm #{local_sql} #{backup_sql} #{server_sql} #{merged_sql}"
  code = sh.run "mv #{merged_db} #{local_db}"
  code = sh.run "mv #{server_db} #{backup_db}"

  pushCommentsDatabase(config)

root.generateCommentsFromDatabase = (config, done) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync?("#{config['database_output']}/#{config['database_scripts']['comments']}")

    # Comments must be cleaned in case previously generated comments were 
    # unpublished.
    clean_generated_comments(config)

    console.log "Generating comments from database..."

    async.waterfall [
      (callback) ->
        new sqlite3.Database("#{config['database_output']}/#{config['database_scripts']['comments']}", (err, db) ->
          callback null, this
        )
      (db, callback) ->

        # TODO: complete comment generation functionality
        db.all( "SELECT _id, message FROM comments WHERE isPublished = 1", (err, rows) ->

          for row in rows

            sql_id = row['_id']
            message = row['message']
            unless doesCommentExist(config, sql_id)
              # Take the input message and build a directory for it.
              build_directory_tree(config, sql_id, message)

        )

      (db, callback) ->
        db.close()
        done(0)
        callback null
    ]

  else
    console.log "Failed to generate comments".red

clean_generated_comments = (config) ->
  if fs.existsSync(config['comments'])
    code = sh.run "rm -rf #{config['comments']}"

doesCommentExist = (config, sql_id) ->
  if !glob.sync("#{config['comments']}/*/#{sql_id}*.md").length == 0
    return true
  else
    return false

# Builds the directory for the comment if it does not exist.
# TODO: This needs to be fixed for the updated notebooks dir struct
build_folder = (config, comment) ->
  folder_name = comment['post_id'].replace(/\//g, '-')
  # The leading character is expected to be a '/' so strip it.
  folder_name = folder_name.substring(1, folder_name.length)
  # do the same for the last character
  folder_name = folder_name.substring(0, folder_name.length - 1)

  unless fs.existsSync("#{config['comments']}/#{folder_name}")
    mkdirp.sync("#{config['comments']}/#{folder_name}")

  folder_name

# Creates the file in the specified folder. If the file exists, the file is not
# written and the application is terminated.
build_file_name = (config, sql_id, comment_id) ->
  # File Name Strucutre: SQLID_COMMENTUID.EXT
  # SQL ID - The autoinc id which helps keeps comments in order.
  # Comment UID - A unique comment id which allows the comment to be linked to
  # via and html id tag. This cannot change, so it is generated at the time of
  # comment submission and embedded within the comment's YAML data.
  file_name = sql_id.toString()
  # In case there are any spaces, replace it with a dash.
  file_name = file_name.replace(/\s/g, '_')

  file_name += "_" + comment_id  + "." + config['comment_ext']

# Generates a gravatar hash based on the email address.
generate_gravatar_hash = (config, email_address) ->
  if email_address
    hashed_email_address = crypto.createHash('md5').update(email_address.trim().toLowerCase()).digest('hex')
  else
    hashed_email_address = crypto.createHash('md5').update(crypto.randomBytes(8) + "#{config['base_url']}").digest('hex')

# If a name was provided, returns the name. Otherwise, returns a default name
get_or_set_name = (config, name) ->
  if name
    return name
  else
    return config['comments_author']

# The main process for building and creating all components for the comment
# file.
#
# message - a string containing yaml formatted data
build_directory_tree = (config, sql_id, message) ->
  try
    comment = yaml.safeLoad(message)
  catch e
    console.log(e)

  folder_name = build_folder(config, comment)
  file_name = build_file_name(config, sql_id, comment['id'])

  comment_path = config['comments'] + "/" + folder_name + "/" + file_name

  # Add some data to the YAML hash
  comment['gravatar_hash'] = generate_gravatar_hash(config, comment['email'])
  comment['name'] = get_or_set_name(config, comment['name'])

  # To imitate the Wintersmith front-matter style, we move the comment
  # content and place it below the actual front-matter.
  comment_content = comment['comment']
  delete comment['comment']

  # Build a string of the complete YAML hash
  # If file exists, don't overwrite it. Terminate the application.
  if fs.existsSync(comment_path)
    process.exit()
  else
    yaml_dump = "---\n" + yaml.safeDump(comment) + "---\n\n#{comment_content}"
    fs.writeFileSync(comment_path, yaml_dump)

root.listComments = (config, done) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")
    console.log "Comments pending approval:"
    console.log ""

    async.waterfall [
      (callback) ->
        new sqlite3.Database("#{config['database_output']}/#{config['database_scripts']['comments']}", (err) ->
          callback null, this
        )
      (db, callback) ->

        db.all( "SELECT _id, message, isPublished FROM comments", (err, rows) ->

          for row in rows
            message = row['message']
            comment = yaml.safeLoad(message)

            list_data = {}
            list_data['Post-ID'] = row['_id']
            list_data['Post'] = comment['post_id']
            list_data['Author'] = get_or_set_name(config, comment['name'])
            list_data['Published'] = row['isPublished']

            array_sizes = []
            longest_key = 0
            longest_key_size = 0
            keys_array = Object.keys(list_data)

            for i in [0..(keys_array.length-1)] by 1
              if keys_array[i].length > longest_key_size
                longest_key_size = keys_array[i].length
                longest_key = keys_array[i]

            for key, value of list_data
              sh.run "printf  \"%-#{longest_key.length}s: %s\n\" \"#{key}\" \"#{value}\""
            console.log ""

          callback null, db

        )

      (db, callback) ->
        db.close()
        done(0)
        callback null
    ]

  else
    console.log "Comments database does not exist.".red

root.viewComment = (config, id, done) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")
    console.log "Reviewing comment #{id}:"
    console.log ""

    async.waterfall [
      (callback) ->

        new sqlite3.Database("#{config['database_output']}/#{config['database_scripts']['comments']}", (err) ->
          callback null, this
        )

      (db, callback) ->
        db.get( "SELECT _id, message, isPublished FROM comments WHERE _id = #{id}", (err, row) ->

          message = row['message']
          comment = yaml.safeLoad(message)

          list_data = {}
          list_data['Post-ID'] = row['_id']
          list_data['Post'] = comment['post_id']
          list_data['Author'] = get_or_set_name(config, comment['name'])
          list_data['Email'] = comment['email']
          list_data['Website'] = comment['link']
          list_data['Published'] = row['isPublished']
          list_data['Message'] = comment['comment']

          array_sizes = []
          longest_key = 0
          longest_key_size = 0
          keys_array = Object.keys(list_data)

          for i in [0..(keys_array.length-1)] by 1
            if keys_array[i].length > longest_key_size
              longest_key_size = keys_array[i].length
              longest_key = keys_array[i]

          for key, value of list_data
            if key != 'Message'
              sh.run "printf  \"%-#{longest_key.length}s: %s\n\" \"#{key}\" \"#{value}\""
            else
              sh.run "printf  \"%-#{longest_key.length}s: \n\n\" \"#{key}\""
              for line in value.split("\\n")
                sh.run "printf \"    %s\" \"#{line}\""
              console.log "\n"

          callback null, db

        )

      (db, callback) ->
        db.close()
        done(0)
        callback null
    ]

  else
    console.log "Comments database does not exist".red

root.deleteComment = (config, id, done) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")
    console.log "Deleting comment #{id}..."

    async.waterfall [
      (callback) ->
        new sqlite3.Database("#{config['database_output']}/#{config['database_scripts']['comments']}", (err, db) ->
          callback null, this
        )
      (db, callback) ->

        db.exec("DELETE FROM comments WHERE _id = #{id}", (err) ->
          callback null, db
        )

      (db, callback) ->
        db.close()
        done(0)
        callback null
    ]


  else
    console.log "Comments database does not exist".red

root.publishComment = (config, id, done) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")
    console.log "Publishing comment #{id}..."

    async.waterfall [
      (callback) ->
        new sqlite3.Database("#{config['database_output']}/#{config['database_scripts']['comments']}", (err, db) ->
          callback null, this
        )
      (db, callback) ->

        db.exec("UPDATE comments SET isPublished = 1 WHERE _id = #{id}", (err) ->
          callback null, db
        )

      (db, callback) ->
        db.close()
        done(0)
        callback null
    ]

  else
    console.log "Comments database does not exist".red

root.unpublishComment = (config, id, done) ->
  # Do not attempt to extract comments from a file that does not exist.
  if fs.existsSync("#{config['database_output']}/#{config['database_scripts']['comments']}")
    console.log "Unpublishing comment #{id}..."

    async.waterfall [
      (callback) ->
        new sqlite3.Database("#{config['database_output']}/#{config['database_scripts']['comments']}", (err, db) ->
          callback null, this
        )
      (db, callback) ->

        db.exec("UPDATE comments SET isPublished = 0 WHERE _id = #{id}", (err) ->
          callback null, db
        )

      (db, callback) ->
        db.close()
        done(0)
        callback null
    ]

  else
    console.log "Comments database does not exist.".red

