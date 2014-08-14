eco = require('eco')
fs = require('fs')
chalk = require('chalk')

module.exports = (grunt) ->
  grunt.task.registerMultiTask 'eco', 'Compile eco to html', ->
    options = @options
      context: {}

    @files.forEach (f) ->
      f.src.filter (filepath) ->
        if (!grunt.file.exists(filepath))
          return false
        else
          return true
      .forEach (filepath) ->
          src = grunt.file.read(filepath)
          try
            compiled = eco.render(src, options.context)
          catch e
            grunt.log.error(e)
            grunt.fail.warn('Eco failed to compile ' + filepath)
            return false
          grunt.file.write(f.dest, compiled)
          grunt.log.writeln('File ' + chalk.cyan(f.dest) + ' created.')
