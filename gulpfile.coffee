gulp = require 'gulp'
glut = require 'glut'

coffee = require 'gulp-coffee'

glut gulp,
  livereload: false
  tasks:
    coffee:
      src: 'src/**/*.coffee'
      dest: 'lib'
      runner: coffee
    copy:
      src: 'src/**/*.json'
      dest: 'lib'
    assets:
      src: [
        'assets/**'
        '!kerplunk-'
      ]
      dest: 'public'
