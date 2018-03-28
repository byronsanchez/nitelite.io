bootstrap = require('../bootstrap.coffee')
env = bootstrap.env
config = bootstrap.env.config

build = require(config['support']).build
fs = require 'fs'
sh = require 'child_process'
colors = require 'colors'

module.exports = (grunt) ->

  #####################
  # LOAD PACKAGED TASKS
  #####################

  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-smushit"
  grunt.loadNpmTasks "grunt-sass"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-wintersmith"
  grunt.loadNpmTasks "grunt-shell"

  # Project configuration.
  grunt.initConfig

    # Store your Package file so you can reference its specific data whenever necessary
    pkg: grunt.file.readJSON("package.json")
    nl: config

    # Minify (Vendor) JS
    uglify:
      options:
        mangle: false
      my_target:
        files:
          'contents/js/jquery.min.js': ['bower_components/jquery/jquery.min.js'],
          'contents/js/foundation.min.js': ['bower_components/foundation/js/foundation.min.js'],

    sass:
      options:
        includePaths: ['bower_components/foundation/scss']
      dist:
        options:
          outputStyle: 'expanded'
        files: [{
          expand: true
          flatten: true
          src: ['sass/main.scss', 'sass/ie9.scss', 'sass/print.scss']
          dest: 'contents/css'
          ext: '.css'
        }]
        # files:
        #   'contents/css/main.css': 'sass/main.scss'

    # Coffeescript
    coffee:
      join:
        options:
          join: true
        files:
          # "contents/js/test.js": "coffee/test.coffee" # 1:1 compile
          "contents/js/main.js": ["coffee/*.coffee"] # compile and concat into single file
      # compile:
      # files:
      # 'contents/js/test.js': 'coffee/test.coffee', # 1:1 compile
      # 'contents/js/test2.js': ['coffee/*.coffee'] # compile and concat into
      # single file

    # Concatenation
    concat:
      options:
        separator: ";"
      libs:
        src: [
          "bower_components/spin.js/spin.js",
          "bower_components/spin.js/jquery.spin.js",
          'bower_components/jreject/js/jquery.reject.js'
        ]
        dest: "contents/js/libs.js"

    copy:
      precompile:
        nonull: true,
        files: [
          {
            expand: true,
            src: ['bower_components/foundation-icons/foundation_icons_social/fonts/*'],
            dest: 'contents/fonts',
            filter: 'isFile',
            flatten: true
          },

          {
            expand: true,
            src: ['bower_components/foundation-icons/foundation_icons_general/fonts/*'],
            dest: 'contents/fonts',
            filter: 'isFile',
            flatten: true
          }
        ]

      postcompile:
        nonull: true,
        files: [

          {
            expand: true,
            src: ['assets/database/**'],
            dest: '<%= nl.destination %>',
            filter: 'isFile',
            flatten: false
          },

          {
            expand: true,
            src: ['assets/support/*'],
            dest: '<%= nl.destination %>/assets',
            filter: 'isFile',
            flatten: true
          },

          {
            expand: true,
            src: ['resources/img/blog/*'],
            dest: '<%= nl.destination %>/img/blog',
            filter: 'isFile',
            flatten: true
          }
        ]

    # Wintersmith
    wintersmith:
      build:
        options:
          action: "build"
          config: "config.json"

    shell:
      npminstall:
        options:
          stdout: true
        command: [
          'cd build/assets',
          'npm install',
          'npm rebuild'
        ].join('&&')
      permissions:
        options:
          stdout: true
        command: [
          'find build/ -type d -exec chmod u=rwx,g=rx,o= "{}" \\;',
          'find build/ -type f -exec chmod u=rw,g=r,o= "{}" \\;',
          'pwd'
        ].join('&&')


  grunt.registerTask('precompile', 'Compiles assets necessary before the website itself can be compiled.', () ->
    build.build_db(config)
  )

  grunt.registerTask('wintersmith-build', 'Compile every file used for the website', () ->
    build.build_db(config)
    build.compile_site(config)

    console.log "Local compilation complete!".green
  )

  grunt.registerTask('clean', 'Perform a clean of any generated files', () ->
    console.log "Cleaning #{config['destination']}..."
    code = sh.execSync "rm -rf #{config['destination']}"
  )

  grunt.registerTask('test', 'Build the application and run all tests', () ->
    # TODO: build and invoke tests
  )

  grunt.registerTask('build-tests', 'Build tests without running them', () ->
    # TODO: build tests
  )

  grunt.registerTask('run-tests', 'Run tests without building them', () ->
    # TODO: invoke tests
  )

  grunt.registerTask('rebuild', 'Build any bindings used by the app', () ->
    console.log "Compiling all bindings..."
    code = sh.execSync "npm rebuild --force"

    console.log "Compilation of bindings complete!".green
  )

  grunt.registerTask 'build', ['uglify', 'sass:dist', 'copy:precompile', 'coffee:join', 'concat', 'wintersmith-build', 'shell:npminstall', 'copy:postcompile', 'shell:permissions']

  grunt.registerTask('default', 'build')

