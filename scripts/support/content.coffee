root = exports ? this

sh = require 'execSync'
fs = require 'fs'
yaml = require('js-yaml')
path = require('path')
_ = require('underscore')
moment = require 'moment'

# List all files in a directory in Node.js recursively in a synchronous fashion
walkSync = (dir, filelist) ->

  if ( dir[dir.length-1] != '/')
    dir = dir.concat('/')

  files = fs.readdirSync(dir)
  filelist = filelist || []

  files.forEach( (file) ->
    if (fs.statSync(dir + file).isDirectory())
      filelist = walkSync(dir + file + '/', filelist)
    else
      filelist.push(dir+file)
  )

  return filelist

root.move_file = (src_path, dst_path) ->
  source = fs.createReadStream(src_path)
  dest = fs.createWriteStream(dst_path)
  source.pipe(dest)
  source.on('end', () ->
  )
  source.on('error', (err) ->
  )

# Build a hash ball on all or subset of files:  abs path -> yaml hash
# perform the requested operation (set value or delete value)
# write the hash ball
root.update_yaml_bulk = (config, yaml_key, yaml_value, skill, notebook_type) ->
  notebook_hash = {}
  notebook_directory = config.source + "/" + config.contents + "/notebooks"

  # If a subset of the notebooks was specified, only parse those
  if (typeof skill != 'undefined' && skill)
    notebook_directory = notebook_directory + "/" + skill
    if (typeof notebook_type != 'undefined' && notebook_type)
      notebook_directory = notebook_directory + "/" + notebook_type

  # If tags are being updated, parse yaml_value to build an array of tags
  if (typeof yaml_key != 'undefined' && yaml_key)
    if (yaml_key == "tags")
      if (typeof yaml_value != 'undefined' && yaml_value)
        yaml_value = yaml_value.split(",")
      else
        # This means tags will always exist in the front-matte
        yaml_value = []

  console.log "Updating all notes in directory: #{notebook_directory}"

  # 1 - yaml front matter from --- to before end ---
  # 2 - yaml front matter end --- and all newlines until before the start of
  # content
  # 3 - yaml front matter end without newlines
  # 4 - content after yaml front matter
  regexp = /^(---\s*\n[\s\S]*?\n?)^((---|\.\.\.)\s*$\n?)^([\s\S]*\n?)/m

  filelist = walkSync(notebook_directory)

  filelist.forEach ( (file) ->

    # skip files that don't have #{post_ext} as the extension
    if (path.extname(file) != ".#{config["post_ext"]}")
      # this does not break. _.each will always run
      # the iterator function for the entire array
      # return value from the iterator is ignored
      return

    file_content = fs.readFileSync(file, "utf8")
    matches_array = file_content.match(regexp)

    if (typeof matches_array != 'undefined' && matches_array)
      yaml_string = matches_array[1]
      content = matches_array[4]

      try
        content_yaml = yaml.safeLoad(yaml_string)
      catch e
        console.log(e)

      notebook_hash[file] = {}
      notebook_hash[file]['original'] = yaml_string
      notebook_hash[file]['new'] = content_yaml
      notebook_hash[file]['content'] = content

      # Perform ops
      if (typeof yaml_value != 'undefined' && yaml_value)
        if (typeof yaml_key != 'undefined' && yaml_key)
          new_value = {}

          # If tags, don't replace, add to existing tags instead
          if (yaml_key == "tags")
            current_tags = notebook_hash[file]['new'][yaml_key]
            # if tags have been previously defined in the target file
            if (typeof current_tags != 'undefined' && current_tags)
              # union removes duplicate tags
              new_value = _.union(current_tags, yaml_value)
              new_value.sort()
            else
              # otherwise, just define the provided tags as a new array
              new_value = yaml_value
              new_value.sort()
          # Otherwise replace the existing value
          else
            new_value = yaml_value

          notebook_hash[file]['new'][yaml_key] = new_value

      else
        delete notebook_hash[file]['new'][yaml_key]

    # Handle the case where no YAML front-matter exists
    else

      notebook_hash[file] = {}
      notebook_hash[file]['original'] = ""
      notebook_hash[file]['new'] = {}
      notebook_hash[file]['content'] = file_content

      # Perform ops - delete is not necessary since no frontmatter exists yet
      if (typeof yaml_value != 'undefined' && yaml_value)
        notebook_hash[file]['new'][yaml_key] = yaml_value

    # write the changes
    yaml_front_matter = "---\n" + yaml.safeDump(notebook_hash[file]['new']) + "---\n\n"
    notebook_hash[file]['new_content'] = yaml_front_matter + notebook_hash[file]['content']

    fs.writeFileSync("#{file}.new", notebook_hash[file]['new_content'] )
    fs.renameSync("#{file}.new", "#{file}")

  )

root.update_title_bulk = (config, skill, notebook_type) ->
  notebook_hash = {}
  notebook_directory = config.source + "/" + config.contents + "/notebooks"

  # If a subset of the notebooks was specified, only parse those
  if (typeof skill != 'undefined' && skill)
    notebook_directory = notebook_directory + "/" + skill
    if (typeof notebook_type != 'undefined' && notebook_type)
      notebook_directory = notebook_directory + "/" + notebook_type

  console.log "Updating all notes in directory: #{notebook_directory}"

  # 1 - yaml front matter from --- to before end ---
  # 2 - yaml front matter end --- and all newlines until before the start of
  # content
  # 3 - yaml front matter end without newlines
  # 4 - content after yaml front matter
  regexp = /^(---\s*\n[\s\S]*?\n?)^((---|\.\.\.)\s*$\n?)^([\s\S]*\n?)/m

  filelist = walkSync(notebook_directory)

  filelist.forEach ( (file) ->

    new_value = path.basename(file, ".#{config["post_ext"]}")

    # skip files that don't have #{post_ext} as the extension
    if (path.extname(file) != ".#{config["post_ext"]}")
      # this does not break. _.each will always run
      # the iterator function for the entire array
      # return value from the iterator is ignored
      return

    file_content = fs.readFileSync(file, "utf8")
    matches_array = file_content.match(regexp)

    if (typeof matches_array != 'undefined' && matches_array)
      yaml_string = matches_array[1]
      content = matches_array[4]

      try
        content_yaml = yaml.safeLoad(yaml_string)
      catch e
        console.log(e)

      notebook_hash[file] = {}
      notebook_hash[file]['original'] = yaml_string
      notebook_hash[file]['new'] = content_yaml
      notebook_hash[file]['content'] = content

      notebook_type = notebook_hash[file]['new']['notebook']

      if (typeof notebook_type == 'undefined' || !notebook_type)
        notebook_type = path.basename(path.dirname(file))

      if (typeof notebook_type != 'undefined' && notebook_type)

        # remove the date from journals; I only use them for ordering in 
        # directory listings for the actual posts. but that data is preserved in 
        # YAML front-matter
        if notebook_type == "journal" or notebook_type == "log" or notebook_type == "kaomea" or notebook_type == "dvasa"
          # Remove leading date
          new_value = new_value.substring(11, new_value.length)

        # Replace triple dashes with temporary token
        new_value = new_value.replace(/---/g, ' %dash% ')
        # Replace dashes with spaces
        new_value = new_value.replace(/-/g, ' ')
        # Replace tokens with preserved dashes
        new_value = new_value.replace(/%dash%/g, ' - ')
        # Capitalize words
        new_value = (new_value.split(' ').map (word) ->
          if (typeof word != 'undefined' && word)
            word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
        # Remove multiple spaces between words (can be caused by multiple
        # dashes).
        new_value = new_value.replace(/\s\s+/g, ' ')

        notebook_hash[file]['new']['title'] = new_value

    # Handle the case where no YAML front-matter exists
    else

      notebook_hash[file] = {}
      notebook_hash[file]['original'] = ""
      notebook_hash[file]['new'] = {}
      notebook_hash[file]['content'] = file_content

      notebook_type = path.basename(path.dirname(file))

      if (typeof notebook_type != 'undefined' && notebook_type)

        # remove the date from journals; I only use them for ordering in 
        # directory listings for the actual posts. but that data is preserved in 
        # YAML front-matter
        if notebook_type == "journal" or notebook_type == "log" or notebook_type == "kaomea" or notebook_type == "dvasa"
          # Remove leading date
          new_value = new_value.substring(11, new_value.length)

        # Replace triple dashes with temporary token
        new_value = new_value.replace(/---/g, ' %dash% ')
        # Replace dashes with spaces
        new_value = new_value.replace(/-/g, ' ')
        # Replace tokens with preserved dashes
        new_value = new_value.replace(/%dash%/g, ' - ')
        # Capitalize words
        new_value = (new_value.split(' ').map (word) ->
          if (typeof word != 'undefined' && word)
            word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
        # Remove multiple spaces between words (can be caused by multiple
        # dashes).
        new_value = new_value.replace(/\s\s+/g, ' ')

        notebook_hash[file]['new']['title'] = new_value

    # write the changes
    yaml_front_matter = "---\n" + yaml.safeDump(notebook_hash[file]['new']) + "---\n\n"
    notebook_hash[file]['new_content'] = yaml_front_matter + notebook_hash[file]['content']

    fs.writeFileSync("#{file}.new", notebook_hash[file]['new_content'] )
    fs.renameSync("#{file}.new", "#{file}")

  )


