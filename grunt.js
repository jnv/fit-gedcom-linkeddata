/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    server: {
      port: 8000
    },
    reload: {
        //port: 6001,
        proxy: {
            host: 'localhost',
            port: '<config:server.port>' // should match server.port config
        }
    },
    watch: {
      files: ['index.html'],
      tasks: 'reload'
    }
  });

  grunt.loadNpmTasks('grunt-reload');
  // Default task.
  grunt.registerTask('default', 'server reload watch');

};
