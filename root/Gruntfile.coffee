path = require('path')
stylus = require('stylus')
growl = require('growl')
Map = require('collections/map')
FileModifiedWatcher = require('./FileModifiedWatcher')

module.exports = (grunt) ->

  src = 'src'
  out = 'out'
  srcHtml = "#{src}/html"
  outHtml = "#{out}/html"
  srcTheme = "#{src}/theme"
  outTheme = "#{out}/theme"
  documents = "#{srcTheme}/documents"
  files = "#{srcTheme}/files"

  filters =
    raw: (block) -> block
    php: (block) -> '<?php ' + block + ' ?>'
    stylus: (block) ->
      # https://github.com/LearnBoost/stylus/issues/230
      # https://github.com/LearnBoost/stylus/issues/151
      css = ''
      stylus.render block, (err, res) ->
        css = res
      css

  themeOptions =
    'Theme Name': 'Hacker Theme'
    Template: 'twentyeleven'
    Version: '0.0.0'

  secret = require('./secret.json')

  modified = new FileModifiedWatcher(grunt, cwd: outTheme)

  grunt.initConfig
    # Options
    # Transformer tasks
    clean:
      html: [outHtml]
      theme: [outTheme]
    copy:
      html:
        files: [
          expand: true
          cwd: srcHtml
          src: ['**/*.html']
          dest: outHtml
        ]
      theme:
        files: [
          {
            expand: true
            cwd: files
            src: ['**']
            dest: outTheme
          }
        ]
    eco:
      html:
        files: [
          expand: true
          cwd: srcHtml
          src: '**/*.eco'
          dest: outHtml
          ext: ''
          extDot: 'last'
        ]
        options:
          context:
            stylus: filters.stylus
      theme:
        files: [
          expand: true
          cwd: documents
          src: '**/*.eco'
          dest: outTheme
          ext: ''
          extDot: 'last'
        ]
    coffeecup:
      html:
        files: [
          expand: true
          cwd: srcHtml
          src: '**/*.coffee'
          dest: outHtml
          ext: ''
          extDot: 'last'
        ]
        options:
          context: {}
          locals: {}
          format: true
          autoescape: true
      theme:
        files: [
          expand: true
          cwd: documents
          src: '**/*.{php,html}.coffee'
          dest: outTheme
          ext: ''
          extDot: 'last'
        ]
        options:
          context: {}
          locals: {}
          format: true
          autoescape: true
          hardcode:
            php: (block) -> text(filters.php(block))
    jade:
      html:
        files: [
          expand: true
          cwd: srcHtml
          src: '**/*.jade'
          dest: outHtml
          ext: ''
          extDot: 'last'
        ]
        options:
          pretty: true
          compileDebug: false
      theme:
        files: [
          expand: true
          cwd: documents
          src: '**/*.jade'
          dest: outTheme
          ext: ''
          extDot: 'last'
        ]
        options:
          pretty: true
          compileDebug: false
          filters:
            raw: filters.raw
            php: filters.php
            stylus: filters.stylus
    stylus:
      html:
        files: [
          expand: true
          cwd: srcHtml
          src: '**/*.styl'
          dest: outHtml
          ext: ''
          extDot: 'last'
        ]
        options:
          compress: false
      stylecss:
        files: [
          expand: true
          cwd: documents
          src: 'style.styl'
          dest: outTheme
          ext: ''
          extDot: 'last'
        ]
        options:
          compress: false
          banner: "/*\n" +
            ("#{key}: #{value}\n" for own key, value of themeOptions).reduce(((a, b) -> a + b), '') +
            '*/'
      theme:
        files: [
          expand: true
          cwd: documents
          src: '**/*.styl'
          dest: outTheme
          ext: ''
          extDot: 'last'
        ]
        options:
          compress: false
    # Deployment tasks
    wpedit:
      html:
        posts:
          [
            # {id, file, {post_type, post_content, ...}}
            {id: 1, file: 'hello-world'}
          ]
        options:
          wp:
            username: secret.{%= remotewp %}.username
            password: secret.{%= remotewp %}.password
          xmlrpc:
            host: secret.{%= remotewp %}.host
            path: '/xmlrpc.php'
          cwd: outHtml
    sftp:
      theme:
        files:
          './': outTheme + '/**'
        options:
          path: secret.{%= remotesftp %}.path + '/'
          createDirectories: true
          showProgress: true
          host: secret.{%= remotesftp %}.host
          username: secret.{%= remotesftp %}.username
          password: secret.{%= remotesftp %}.password
          port: secret.{%= remotesftp %}.port
          srcBasePath: outTheme + '/'
    # Watch tasks
    watch:
      html:
        files: [srcHtml + '/**']
        tasks: ['compile:html']
        options:
          spawn: false
      'html-deploy':
        files: [srcHtml + '/**']
        tasks: ['deploy:html']
        options:
          spawn: false
          livereload: true
      theme:
        files: [srcTheme + '/**']
        tasks: ['compile:theme']
        options:
          spawn: false
      'theme-deploy':
        files: [srcTheme + '/**']
        tasks: ['deploy:theme']
        options:
          spawn: false
          livereload: true

  require('load-grunt-tasks')(grunt, scope: 'devDependencies')
  grunt.loadTasks('./tasks')

  grunt.registerTask(key, value) for own key, value of {
    'compile:html': [
      'newer:jade:html'
      'newer:coffeecup:html'
      'newer:eco:html'
      'newer:copy:html'
    ]
    'deploy:html': [
      'compile:html'
      'wpedit:html'
    ]
    'compile:theme': [
      'newer:copy:theme'
      'newer:jade:theme'
      'newer:stylus:stylecss'
      'newer:stylus:theme'
      'newer:coffeecup:theme'
      'newer:eco:theme'
    ]
    'compile:theme-all': [
      'clean:theme'
      'compile:theme'
    ]
    'deploy:theme': [
      'compile:theme'
      'sftp:theme'
      'notify-postdeploy-theme'
    ]
    'deploy:theme-all': [
      'compile:theme-all'
      'sftp:theme'
      'notify:postdeploy-theme'
    ]
    'deploy-theme': [
      'record-mtime'
      'compile-theme-complete'
      'set-files-to-upload'
      'sftp:theme'
      'notify-postdeploy-theme'
    ]
    'notify-postdeploy-theme': ->
      growl('Deploy theme complete.')
    'record-mtime': ->
      modified.recordMtime()
    'set-files-to-upload': ->
      grunt.config('sftp.theme.files', './': modified.getModifiedFiles())
    'setProcessedFiles': ->
      grunt.task.requires('sftp:theme')
      modified.setProcessedFiles(true)
    'default': [
      'compile:theme'
      'compile:html'
      ->
        grunt.spawn
    ]
  }

  grunt.registerTask('compile-html', ['jade:html', 'coffeecup:html', 'wpedit:html'])
