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

config['source'] = root.env['workDir']
config['destination'] = config['output']

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
config['database'] = path.join(config['source'], "contents/database")
# config['database_scripts'] = {"comments": "comments.db", "path": "path.db"}
config['database_scripts'] = {"path": "path.db"}
config['database_output'] = path.join(config['database'], "bin")

