bootstrap = require('../bootstrap.coffee')
env = bootstrap.env
config = bootstrap.env.config

content = require(config['support']).content
fs = require 'fs'
sh = require 'execSync'
path = require 'path'
colors = require 'colors'
glob = require 'glob'
moment = require 'moment'
sleep = require 'sleep'
yaml = require('js-yaml')

module.exports = (grunt) ->

  grunt.registerTask('post', 'Create a post', (skill, notebook, title) ->
    if !fs.existsSync(config['posts'])
      console.log "grunt task aborted: #{config['posts']} directory not found.".red
      process.exit()

    if !skill
      console.log "Please pick a skill to write about.".red
      process.exit()

    if !notebook
      console.log "Please pick a notebook to write in.".red
      process.exit()

    if !title
      console.log "Please add a title to your post.".red
      process.exit()

    skill = skill.trim()
    notebook = notebook.trim()
    title = title.trim()

    skillpath = "#{config['posts']}/#{skill}"
    notebookpath = "#{skillpath}/#{notebook}"

    # ensure journal entries have dates in the filename
    filename = "#{title.replace(/(\'|\!|\?|\:|\s\z)/g, '').replace(/\s/g, '-').toLowerCase()}"
    filepath = "#{notebookpath}/#{filename}.#{config['post_ext']}"
    if !fs.existsSync("#{filepath}")
      if notebook == "journal" or notebook == "logs"
        date = moment().format("YYYY-MM-DD")
        filename = "#{date}-#{title.replace(/(\'|\!|\?|\:|\s\z)/g, '').replace(/\s/g, '-').toLowerCase()}"
      else
        filename = "#{title.replace(/(\'|\!|\?|\:|\s\z)/g, '').replace(/\s/g, '-').toLowerCase()}"

    filepath = "#{notebookpath}/#{filename}.#{config['post_ext']}"

    # create directories if they don't exist yet
    if !fs.existsSync("#{skillpath}")
      fs.mkdirSync("#{skillpath}")
    if !fs.existsSync("#{notebookpath}")
      fs.mkdirSync("#{notebookpath}")

    if fs.existsSync("#{filepath}")

      if config['editor']
        sleep.sleep 2
        code = sh.run "#{config['editor']} #{filepath}"
        process.exit()
      else
        console.log "The post already exists.".red
        process.exit()

    else
      console.log "Creating new post: #{filepath}"

      yaml_front_matter = "---\n\
title: \"#{title.replace(/-/g,' ')}\"\n\
author: \"#{config.locals['author']}\"\n\
description: false\n\
date:\n\
category: #{skill}\n\
comments_enabled: true\n\
template: layouts/article.jade\n\
tags: []\n\
published: 0\n\
---"

      fs.writeFileSync("#{filepath}", yaml_front_matter)
      console.log "#{filepath} has been created."

      if config['editor']
        sleep.sleep 2
        code = sh.run "#{config['editor']} #{filepath}"
        process.exit()
  )

  # TODO: abstract unpublish and publish tasks yaml loading into a function
  grunt.registerTask('unpublish', 'Unpublish a published post', (skill, notebook, title) ->

    # 1 - yaml front matter from --- to before end ---
    # 2 - yaml front matter end --- and all newlines until before the start of
    # content
    # 3 - yaml front matter end without newlines
    # 4 - content after yaml front matter
    regexp = /^(---\s*\n[\s\S]*?\n?)^((---|\.\.\.)\s*$\n?)^([\s\S]*\n?)/m

    if !title

      notebook_hash = {}
 
      if skill
        skill = skill.trim()
        if notebook
          notebook = notebook.trim()

      if skill
        if notebook
          files = glob.sync(path.join(config['posts'],  "/#{skill}/#{notebook}/**/*.#{config['post_ext']}"))
        else
          files = glob.sync(path.join(config['posts'],  "/#{skill}/**/*.#{config['post_ext']}"))
      else
        files = glob.sync(path.join(config['posts'],  "/**/*.#{config['post_ext']}"))

      for f in files

        file_content = fs.readFileSync(f, "utf8")
        matches_array = file_content.match(regexp)

        if (typeof matches_array != 'undefined' && matches_array)
          yaml_string = matches_array[1]
          content = matches_array[4]

          try
            content_yaml = yaml.safeLoad(yaml_string)
          catch e
            console.log(e)

          notebook_hash[f] = {}
          notebook_hash[f]['published'] = content_yaml["published"] || 0
        else
          content = file_content
          notebook_hash[f] = {}
          notebook_hash[f]['published'] = 0

        if notebook_hash[f]['published'] == "1" || notebook_hash[f]['published'] == 1
          basename = path.basename(f, "." + config['post_ext'])
          notebookdir = path.dirname(f)
          notebookname = path.basename(notebookdir)
          skilldir = path.dirname(notebookdir)
          skillname = path.basename(skilldir)
          console.log skillname + "/" + notebookname + "/" + basename

    else

      filename = "#{title}"

      if !skill
        console.log "Please pick a skill.".red
        process.exit()

      if !notebook
        console.log "Please pick a notebook.".red
        process.exit()

      if !title
        console.log "Please pick a post.".red
        process.exit()

      skill = skill.trim()
      notebook = notebook.trim()
      title = title.trim()

      skillpath = "#{config['posts']}/#{skill}"
      notebookpath = "#{skillpath}/#{notebook}"
      filepath = "#{notebookpath}/#{filename}.#{config['post_ext']}"

      fileContent = fs.readFileSync("#{filepath}", 'utf8')
      parsed_content = fileContent.replace("published: 1", "published: 0")
      parsed_content = parsed_content.replace("published: \"1\"", "published: \"0\"")
      fs.writeFileSync("#{filepath}.new", parsed_content )
      fs.renameSync("#{filepath}.new", "#{filepath}")
      console.log "#{filepath} has been unpublished."

  )

  grunt.registerTask('publish', 'Publish a draft post', (skill, notebook, title) ->

    # 1 - yaml front matter from --- to before end ---
    # 2 - yaml front matter end --- and all newlines until before the start of
    # content
    # 3 - yaml front matter end without newlines
    # 4 - content after yaml front matter
    regexp = /^(---\s*\n[\s\S]*?\n?)^((---|\.\.\.)\s*$\n?)^([\s\S]*\n?)/m

    if !title

      notebook_hash = {}
 
      if skill
        skill = skill.trim()
        if notebook
          notebook = notebook.trim()

      if skill
        if notebook
          files = glob.sync(path.join(config['posts'],  "/#{skill}/#{notebook}/**/*.#{config['post_ext']}"))
        else
          files = glob.sync(path.join(config['posts'],  "/#{skill}/**/*.#{config['post_ext']}"))
      else
        files = glob.sync(path.join(config['posts'],  "/**/*.#{config['post_ext']}"))

      for f in files

        file_content = fs.readFileSync(f, "utf8")
        matches_array = file_content.match(regexp)

        if (typeof matches_array != 'undefined' && matches_array)
          yaml_string = matches_array[1]
          content = matches_array[4]

          try
            content_yaml = yaml.safeLoad(yaml_string)
          catch e
            console.log(e)

          notebook_hash[f] = {}
          notebook_hash[f]['published'] = content_yaml["published"] || 0
        else
          content = file_content
          notebook_hash[f] = {}
          notebook_hash[f]['published'] = 0

        if notebook_hash[f]['published'] != "1" && notebook_hash[f]['published'] != 1
          basename = path.basename(f, "." + config['post_ext'])
          notebookdir = path.dirname(f)
          notebookname = path.basename(notebookdir)
          skilldir = path.dirname(notebookdir)
          skillname = path.basename(skilldir)
          console.log skillname + "/" + notebookname + "/" + basename

    else

      notebook_entry = {}
      date = moment().format("YYYY-MM-DD")
      filename = "#{title}"

      if !skill
        console.log "Please pick a skill to write about.".red
        process.exit()

      if !notebook
        console.log "Please pick a notebook to write in.".red
        process.exit()

      if !title
        console.log "Please add a title to your post.".red
        process.exit()

      skill = skill.trim()
      notebook = notebook.trim()
      title = title.trim()

      skillpath = "#{config['posts']}/#{skill}"
      notebookpath = "#{skillpath}/#{notebook}"
      filepath = "#{notebookpath}/#{filename}.#{config['post_ext']}"

      fileContent = fs.readFileSync("#{filepath}", 'utf8')

      matches_array = fileContent.match(regexp)

      if (typeof matches_array != 'undefined' && matches_array)
        yaml_string = matches_array[1]
        content = matches_array[4]

        try
          content_yaml = yaml.safeLoad(yaml_string)
        catch e
          console.log(e)
        notebook_entry = content_yaml
      else
        content = fileContent
        notebook_entry = {}


      # set defaults or prompt for a value
      # required fields:
      # - title
      # - description?
      # - date
      # - category
      # - comments_enabled?
      # - template
      # - tags?
      # - author?
      # - published
      if !notebook_entry['title']
        console.log "entry does not have title! please add a title before attempting to publish.".red
        if config['editor']
          sleep.sleep 2
          code = sh.run "#{config['editor']} #{filepath}"
        process.exit()
      if !notebook_entry['description']
        notebook_entry['description'] = false
      if !notebook_entry['date']
        notebook_entry['date'] = "#{date} #{moment().format('HH:mm:ss')}"
      if !notebook_entry['category']
        notebook_entry['category'] = "#{skill}"
      if !notebook_entry['comments_enabled']
        notebook_entry['comments_enabled'] = true
      if !notebook_entry['template']
        notebook_entry['template'] = "layouts/article.jade"
      if !notebook_entry['tags']
        notebook_entry['tags'] = []
      if !notebook_entry['author']
        notebook_entry['author'] = config['locals']['author']
      notebook_entry['published'] = 1

      # write the changes
      yaml_front_matter = "---\n" + yaml.safeDump(notebook_entry) + "---\n\n"
      updated_content = yaml_front_matter + content

      fs.writeFileSync("#{filepath}.new", updated_content )
      fs.renameSync("#{filepath}.new", "#{filepath}")

      console.log "#{filepath} has been published."

      if config['editor']
        sleep.sleep 2
        code = sh.run "#{config['editor']} #{filepath}"
        process.exit()
  )

  grunt.registerTask('page', 'Create a page', (title) ->
    if !title
      console.log "Please add a title to your page.".red
      process.exit()

    title = title.trim()
    filepath = "#{title.replace(/(\'|\!|\?|\:|\s\z)/g, '').replace(/\s/g, '-').toLowerCase()}"
    filename = "index.#{config['post_ext']}"

    fs.mkdirSync("#{config['contents']}/#{filepath}")

    if fs.existsSync("#{config['contents']}/#{filepath}/#{filename}")
      console.log "The page already exists.".red
    else
      console.log "Creating new page: #{config['contents']}/#{filepath}/#{filename}"

      yaml_front_matter = "---\n\
title: \"#{title.replace(/-/g,' ')}\"\n\
description: \"\"\n\
template: layouts/page.jade\n\
---"

      fs.writeFileSync("#{config['contents']}/#{filepath}/#{filename}", yaml_front_matter)
      console.log "#{config['contents']}/#{filepath}/#{filename} was created."
      if config['editor']
        sleep.sleep 2
        code = sh.run "#{config['editor']} #{config['contents']}/#{filepath}/#{filename}"
  )

  grunt.registerTask('yaml', 'Change YAML values in bulk', (yaml_key, yaml_value, skill, notebook_type) ->
        content.update_yaml_bulk(config, yaml_key, yaml_value, skill, notebook_type)
  )

  grunt.registerTask('title', 'Change title values in bulk', (skill, notebook_type) ->
        content.update_title_bulk(config, skill, notebook_type)
  )


