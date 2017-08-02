root = exports ? this

path = require('path')
yaml = require('js-yaml')
fs   = require('fs')
ws   = require('wintersmith')

config_file = path.join(__dirname, '..') + '/' + 'config.json'

load_configuration = () ->
  try
    config = yaml.safeLoad(fs.readFileSync(config_file, 'utf8'))
  catch e
    console.log(e)
  merge_wintersmith_configuration(config)

merge_wintersmith_configuration = (config) ->
  env = ws(config)

root.env = load_configuration()
env = root.env
config = root.env.config

###########################
# Grunt Tasks Configuration
###########################

deployment = config.deployment

config['source'] = root.env['workDir']
config['destination'] = config['output']
deployment['connection_production'] = "#{deployment['remote_user']}@#{deployment['server_production']}"
deployment['connection_staging'] = "#{deployment['remote_user']}@#{deployment['server_staging']}"
deployment['remote_current_path'] = path.join(deployment['remote_destination'], "current/build")
deployment['remote_assets'] = path.join(deployment['remote_current_path'], "assets")
deployment['remote_database_output'] = "/var/lib/nitelite/webserver/nitelite.io/database"
config['config_file'] = config_file
config['layouts'] = path.join(config['source'], "_layouts")
config['posts'] = path.join(config['source'], "contents/notebooks")
config['comments'] = path.join(config['source'], "contents/comments")
config['scripts'] = path.join(config['source'], "scripts")
config['tasks'] = path.join(config['scripts'], "tasks")
config['support'] = path.join(config['scripts'], "support")
config['vendor'] = path.join(config['source'], "vendor")
config['assets'] = path.join(config['source'], "assets")
config['tests'] = path.join(config['source'], "tests")
config['database'] = path.join(config['assets'], "database")
# config['database_scripts'] = {"comments": "comments.db", "path": "path.db"}
config['database_scripts'] = {"path": "path.db"}
config['database_output'] = path.join(config['database'], "bin")
# Files to remove from compiled source.
config['no_deploy'] = []



