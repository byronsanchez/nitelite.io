root = exports ? this

sh = require 'child_process'
fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
colors = require 'colors'
glob = require 'glob'

# Reads and execute the db schema changescripts in assets/database
root.build_db = (config) ->
  console.log "------------------------------"
  console.log "Generating the site databases."
  console.log "------------------------------"

  fs.mkdirSync(config['database_output']) unless fs.existsSync(config['database_output'])
  for db_dir, db_file of config['database_scripts']
    db_source = "#{config['database']}/#{db_dir}"
    db_dest = "#{config['database_output']}/#{db_file}"

    # Only build the database if it does not already exist
    # The path database can always be rebuilt
    code = sh.execSync "rm -f #{db_dest}" if db_dir == "path"

    if !fs.existsSync(db_dest)
      files = glob.sync(path.join(db_source,  '/sc*'))
      files = files.sort()

      for x in files
        code = sh.execSync "sqlite3 #{db_dest} < #{x}"
      console.log "#{db_file} built successfully!".green
    else
      console.log "#{db_file} already exists".yellow
