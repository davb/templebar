module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-clean');

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    clean: {
      js: ['<%= pkg.name %>*.js'],
      tmp: ['.tmp']
    },
    coffee: {
      dist: {
        files: {
          '.tmp/<%= pkg.name %>-<%= pkg.version %>.js': 'src/*.coffee'
        }
      }
    },
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= pkg.version %> */'
      },
      dist: {
        files: {
          '<%= pkg.name %>-<%= pkg.version %>.min.js': ['.tmp/<%= pkg.name %>*.js']
        }
      }
    }
  });

  grunt.registerTask('default', ['clean', 'coffee', 'uglify', 'clean:tmp']);
};
