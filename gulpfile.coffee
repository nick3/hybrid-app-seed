gulp = require 'gulp'
$ = (require "gulp-load-plugins")()

gulp.task 'styles', ->
  gulp.src 'src/styles/**/*.scss'
    .pipe $.rubySass
      style: 'expanded',
      precision: 10
    .pipe $.autoprefixer 'last 1 version'
    .pipe gulp.dest '.tmp/styles'
    .pipe $.size()

gulp.task 'scripts', ->
  gulp.src 'src/scripts/**/*.coffee'
    .pipe $.coffeelint()
    .pipe $.coffeelint.reporter()
    .pipe $.coffee()
    .pipe gulp.dest '.tmp/scripts'
    .pipe $.size()

gulp.task 'html', ['styles', 'scripts'], ->
  jsFilter = $.filter '**/*.js'
  cssFilter = $.filter '**/*.css'
  
  gulp.src 'src/*.html'
    .pipe $.useref.assets
      searchPath: '{.tmp,app}'
    .pipe jsFilter
    .pipe $.uglify()
    .pipe jsFilter.restore()
    .pipe cssFilter
    .pipe $.csso()
    .pipe cssFilter.restore()
    .pipe $.useref.restore()
    .pipe $.useref()
    .pipe gulp.dest 'www'
    .pipe $.size()

gulp.task 'jade', ->
  gulp.src 'src/views/**/*.jade'
    .pipe jade()
    .pipe gulp.dest 'www/views'
    .pipe $.size()

gulp.task 'images', ->
  gulp.src 'src/images/**/*'
    .pipe $.cache $.imagemin
      optimizationLevel: 3,
      progressive: true,
      interlaced: true
    .pipe gulp.dest 'www/images'
    .pipe $.size()

gulp.task 'fonts', ->
  $.bowerFiles()
    .pipe $.filter '**/*.{eot,svg,ttf,woff}'
    .pipe $.flatten()
    .pipe gulp.dest 'www/fonts'
    .pipe $.size()

gulp.task 'extras', ->
  gulp.src ['src/*.*', '!src/*.html'], { dot: true }
    .pipe gulp.dest 'www'

gulp.task 'clean', ->
  gulp.src ['.tmp', 'www'], { read: false }
    .pipe $.clean()

gulp.task 'build', ['jade', 'images', 'fonts', 'extras']

gulp.task 'default', ['clean'], ->
  gulp.start 'build'

gulp.task 'connect', ->
  connect = require 'connect'
  app = connect()
    .use (require 'connect-livereload') { port: 35729 }
    .use connect.static 'src'
    .use connect.static '.tmp'
    .use connect.directory 'src'

    require 'http'
      .createServer app
      .listen 9000
      .on 'listening', ->
        console.log 'Started connect web server on http://localhost:9000'

gulp.task 'serve', ['connect', 'styles'], ->
  (require 'opn') 'http://localhost:9000'

# inject bower components
gulp.task 'wiredep', ->
  wiredep = (require 'wiredep').stream;

  gulp.src 'src/styles/*.scss'
    .pipe wiredep
      directory: 'src/bower_components'
    .pipe gulp.dest 'src/styles'

  gulp.src 'src/*.html'
    .pipe wiredep
      directory: 'src/bower_components'
    .pipe gulp.dest 'src'

gulp.task 'watch', ['connect', 'serve'], ->
  server = $.livereload()

  # watch for changes

  gulp.watch [
      'src/*.html',
      'src/views/**/*.jade'
      '.tmp/styles/**/*.css',
      '.tmp/scripts/**/*.js',
      'src/images/**/*'
    ]
    .on 'change', (file) ->
      server.changed file.path

  gulp.watch 'src/styles/**/*.scss', ['styles']
  gulp.watch 'src/scripts/**/*.js', ['scripts']
  gulp.watch 'src/views/**/*.jade', ['jade']
  gulp.watch 'src/images/**/*', ['images']
  gulp.watch 'bower.json', ['wiredep']
