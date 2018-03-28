bootstrap = require('../bootstrap.coffee')
env = bootstrap.env
config = bootstrap.env.config

build = require(config['support']).build
fs = require 'fs'
sh = require 'child_process'
colors = require 'colors'

module.exports = (grunt) ->
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-wintersmith"

	#####################
	# LOAD PACKAGED TASKS
	#####################

	# Project configuration.
	grunt.initConfig

# Store your Package file so you can reference its specific data whenever necessary
		pkg: grunt.file.readJSON("package.json")
		nl: config

		wintersmith:
			local: {},
			preview:
				options:
					action: "preview"

# Concatenation
		watch:
			files: ['config.json', 'contents/**/*.html', 'contents/**/*.md', 'plugins/*', 'contents/**/*.scss', 'contents/**/*.coffee', 'contents/**/*.js', 'templates/**/*.jade']
			tasks: ['build-db', 'wintersmith:local']

	grunt.registerTask('build-db', 'Build the sqlite databases used by the site', () ->
		build.build_db(config)

		console.log "SQLite databases compiled!".green
	)

	grunt.registerTask('default', 'build')

