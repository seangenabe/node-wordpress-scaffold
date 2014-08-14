// grunt-init installer: http://gruntjs.com/project-scaffolding

module.exports = {
  description: "Scaffold a WordPress website, including the theme and post contents.",
  warnOn: '*',
  after: 'Install project dependencies with _npm install_.\nCompile your WordPress posts with grunt compile:html.\nCompile your WordPress theme with grunt compile:theme.\nSee your Gruntfile for more.',
  template: function(grunt, init, done) {
    init.process({}, [
      {
        name: 'name'
      },
      {
        name: 'description'
      },
      {
        name: 'remotesftp',
        message: 'SFTP website name (Must be valid JS key)',
        default: 'remotesftp'
      },
      {
        name: 'host',
        message: 'SFTP host (website domain)',
        default: 'localhost'
      },
      {
        name: 'sftpuser',
        message: 'SFTP username'
      },
      {
        name: 'sftppass',
        message: 'SFTP password'
      },
      {
        name: 'remotewp',
        message: 'WP website name (Must be another valid JS key)',
        default: 'remotewp'
      },
      {
        name: 'wpuser',
        message: 'WP username'
      },
      {
        name: 'wppass',
        message: 'WP password'
      }
    ], function(err, props) {

      var files = init.filesToCopy(props);
      init.copyAndProcess(files, props);

      var package_json = {
        name: props.name,
        description: props.description,
        version: '0.0.0',
        node_version: '^0.10',
        devDependencies: {
          'async-q': '^0.2.2',
          'chalk': '^0.4.0',
          collections: "^1.1.0",
          'deep-extend': '^0.2.10',
          eco: '^1.1.0-rc-3',
          growl: "^1.7.0",
          grunt: "^0.4.5",
          'grunt-coffeecup': '^0.1.0',
          'grunt-contrib-clean': '^0.5.0',
          'grunt-contrib-copy': '^0.5.0',
          'grunt-contrib-jade': '^0.12.0',
          'grunt-contrib-stylus': '^0.17.0',
          'grunt-contrib-watch': '^0.6.1',
          'grunt-newer': '^0.7.0',
          'grunt-ssh': '^0.11.2',
          'load-grunt-tasks': '^0.6.0',
          q: '^1.0.1',
          stylus: '^0.46.3',
          xmlrpc: '^1.2.0'
        }
      }
      init.writePackageJSON('package.json', package_json)
      done()
    })
  }
}
