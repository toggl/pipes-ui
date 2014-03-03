var gulp = require('gulp'),
    fs = require('fs'),
    es = require('event-stream'),
    path = require('path'),
    clean = require('gulp-clean'),
    insert = require('gulp-insert'),
    sass = require('gulp-sass'),
    compass = require('gulp-compass'),
    coffee = require('gulp-coffee'),
    concat = require('gulp-concat'),
    uglify = require('gulp-uglify'),
    template = require('gulp-template-compile'),
    preprocess = require('gulp-preprocess'),
    bowerFiles = require("gulp-bower-files"),
    flatten = require('gulp-flatten'),
    livereload = require('gulp-livereload'),
    print = require('gulp-print'),
    filter = require('gulp-filter'),
    gutil = require('gulp-util'),
    notifier = require('node-notifier'),
    Entities = require('html-entities').XmlEntities;
// var imagemin = require('gulp-imagemin'); // TODO

// Custom notification function because gulp-notify doesn't work
var htmlEntities = new Entities();
function logError(error, print) {
  if(print) {
    gutil.log(error);
  }
  msg = htmlEntities.encode(gutil.colors.stripColor(error.message).replace(/[\r\n ]+/g, ' '));
  notifier.notify({
    title: 'Pipes build error',
    message: msg
  });
}

// =====
// Setup
// =====

var paths = {
  scripts: [
    'app/scripts/app.coffee',
    'app/scripts/views/list-view.coffee',
    'app/scripts/**/*.coffee',
    '!app/scripts/vendor/**/*.coffee'
  ], // in specific order => app.js
  styles: ['app/styles/**/*.scss', '!app/styles/vendor/**/*.scss'], // => app.css
  stylesVendorPrepend: 'app/styles/_globals.scss', // special hack to allow configuring of external foundation, prepended to => vendor.css
  stylesVendor: ['app/styles/vendor/**/*.scss'], // => appended to vendor.css after css from bower packages
  templates: ['app/templates/**/*.html'], // window.templates[filepath] = <compiled template>, => templates.js
  index: 'app/index.html',
  images: 'app/images/**/*',
  build: 'build/'
};

// try {
//    var config = require('./config.json');
// } catch(err) {
//   config = {};
//   gutil.log(gutil.colors.yellow('Warning: You need a config.json to be able to deploy'));
// }

var vendorPreScss = ''; // String to prepend to all vendor scss files

gulp.task('_getVendorPreScss', function(cb) { // Registering this as task to be able to specify as task dep
  fs.readFile(paths.stylesVendorPrepend, 'utf8', function (err, data) {
    if(err) return;
    vendorPreScss = data;
    cb();
  });
});

var env = gutil.env.e || 'development';

// =====
// Tasks
// =====

gulp.task('build-assets', function() {
  // Copy files as-is (almost)
  // Project files
  gulp.src(paths.index)
    .pipe(preprocess({context: {ENV: env}}))
    .pipe(gulp.dest(paths.build));
  gulp.src(paths.images)
    .pipe(gulp.dest(paths.build + "images/"));
  // External files
  bowerFiles()
    .pipe(filter('**/*.{otf,eot,svg,ttf,woff}'))
    .pipe(flatten())
    .pipe(gulp.dest(paths.build + 'fonts/'));
});

gulp.task('build-scripts', function() {
  // Project files
  gulp.src(paths.scripts)
    .pipe(coffee())
    .on('error', function(err) { logError(err, true); })
    .pipe(env == 'development' ? gutil.noop() : uglify())
    .pipe(concat('app.js'))
    .pipe(gulp.dest(paths.build + 'scripts/'));
  // External files (bower + scripts/vendor/)
  bowerFiles()
    .pipe(filter('**/*.js'))
    .pipe(filter('!underscore/**/*')) // TODO: Remove this hack (backbone dep not needed)
    .pipe(env == 'development' ? gutil.noop() : uglify())
    .pipe(concat('vendor.js'))
    .pipe(gulp.dest(paths.build + 'scripts/'));
});

gulp.task('build-styles', ['_getVendorPreScss'], function() {
  // Project files
  gulp.src(paths.styles)
    .pipe(compass({
      config_file: 'compass.rb',
      sass: 'app/styles/', // must be same as in compass config
      css: '.tmp/styles/' // must be same as in compass config
    }))
    .on('error', function(err) { logError(err); })
    .pipe(concat("app.css"))
    .pipe(gulp.dest(paths.build + 'styles/'))
  // External files: scss + css (bower + styles/vendor/)
  var scssFilter = filter('**/*.scss')
  es.concat(
    bowerFiles().pipe(filter('**/*.{scss,css}')),
    gulp.src(paths.stylesVendor)
  )
    .pipe(scssFilter)
    .pipe(insert.prepend(vendorPreScss))
    .pipe(sass())
    .on('error', function(err) { logError(err); })
    .pipe(scssFilter.restore())
    .pipe(concat("vendor.css"))
    .pipe(gulp.dest(paths.build + 'styles/'))
});

gulp.task('build-templates', function() {
  // Precompile lodash templates into window.templates["relpath/filename.html", ...]
 return gulp.src(paths.templates)
    .pipe(template({
      namespace: 'templates'
    }))
    .on('error', function(err) { logError(err); })
    .pipe(concat("templates.js"))
    .pipe(gulp.dest(paths.build + 'scripts/'));
});

gulp.task('watch', function () {
  // Watch for changes in files and rebuild them to build/
  // TODO: watch project and external separately for faster changes
  gulp.watch(paths.scripts, ['build-scripts']);
  gulp.watch(paths.styles.concat(paths.stylesVendor, paths.stylesVendorPrepend), ['build-styles']);
  gulp.watch([paths.index, paths.images], ['build-assets']);
  gulp.watch(paths.templates, ['build-templates']);
});

gulp.task('livereload', function () {
  // Trigger browser refresh when smth changes in build/
  var server = livereload(35730);
  gulp.watch(paths.build + '**').on('change', function(file) { server.changed(file.path); });
});

gulp.task('serve', function(next) {
  // Serve files in build/ for local testing
  var staticS = require('node-static'),
      server = new staticS.Server(paths.build),
      port = 7001;
  require('http').createServer(function (request, response) {
    request.addListener('end', function () {
      server.serve(request, response);
    }).resume();
  }).listen(port, function() {
    gutil.log(gutil.colors.green('Server listening on port: ') + gutil.colors.magenta(port));
    next();
  });
});

gulp.task('clean', function() {
  gulp.src(paths.build, {read: false})
    .pipe(clean());
});

gulp.task('build', ['build-scripts', 'build-styles', 'build-assets', 'build-templates']);
gulp.task('default', ['build', 'watch', 'livereload', 'serve']);
