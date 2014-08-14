Q = require('q')
xmlrpc = require('xmlrpc')
fs = require('fs')
util = require('util')
deepExtend = require('deep-extend')
path = require('path')
growl = require('growl')
async = require('async-q')

# The wpedit task will upload the file contents to a WordPress installation.

module.exports = (grunt) ->
  grunt.task.registerMultiTask 'wpedit', 'Uploads file contents to a WordPress installation.', ->
    task = @
    done = @async()
    options = deepExtend({
      cwd: '.'
      wp:
        blogid: 1
        username: 'admin'
        password: ''
      xmlrpc:
        host: '127.0.0.1'
        port: 80
        path: '/xmlrpc.php'
      encoding: 'utf8'
      ext: '.html'
    }, @data.options)

    createClient = ->
      xmlrpc.createClient(options.xmlrpc)

    methodCall = (method, args) ->
      Q.ninvoke(createClient(), 'methodCall', method, args)

    getPost = (id) ->
      methodCall('wp.getPost', [options.wp.blogid, options.wp.username, options.wp.password, id])

    editPost = (id, content) ->
      methodCall('wp.editPost', [options.wp.blogid, options.wp.username, options.wp.password, id, content])

    async.each @data.posts, (post) ->
      struct = post.struct ? {}
      promise3 = Q do ->
        if (post.file?)
          promise1 = getPost(post.id).then (post) -> post.post_content
          filePath = path.resolve(options.cwd, post.file + options.ext)
          promise2 = Q.ninvoke(fs, 'readFile', filePath, encoding: (post.encoding ? options.encoding))
          promise1.then (postContent) ->
            promise2.then (fileContent) ->
              if postContent isnt fileContent
                struct.post_content = fileContent
              struct
        else
          struct
      promise3.then (struct) ->
        ret = null
        for key, value of struct
          ret = editPost(post.id, struct)
          break
        return ret
    .done ->
        growl('HTML deploy complete.', {title: task.target})
        done()
      , (reason) ->
        console.log(reason)
        done(false)
