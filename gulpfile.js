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
    Entities = require('html-entities').XmlEntities,
    shell = require('gulp-shell'),
    bump = require('gulp-bump'),
    tap = require('gulp-tap'),
    rev = require('gulp-rev')
    inject = require('gulp-inject')
    request = require('request'),
    exec = require('child_process').exec;
// var imagemin = require('gulp-imagemin'); // TODO

// Custom notification function because gulp-notify doesn't work for some reason
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
    'app/scripts/views/steps/step.coffee',
    'app/scripts/views/steps/datapoll-step.coffee',
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

var cl = gutil.colors;

var localConfig = null;
try {
  localConfig = require('./local_config.json');
} catch(err) {
  localConfig = null;
  gutil.log(cl.yellow('Warning: You need a local_config.json to be able to deploy or specify api host'));
}

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
  // Copy files as-is
  // Project files
  gulp.src(paths.images)
    .pipe(gulp.dest(paths.build + "images/"));
  // External files
  bowerFiles()
    .pipe(filter('**/*.{otf,eot,svg,ttf,woff}'))
    .pipe(flatten())
    .pipe(gulp.dest(paths.build + 'fonts/'));
});

gulp.task('build-scripts-internal', function() {
  return gulp.src(paths.scripts)
    .pipe(coffee())
    .on('error', function(err) { logError(err, true); })
    .pipe(env == 'development' ? gutil.noop() : uglify())
    .pipe(concat('app.js'))
    .pipe(rev())
    .pipe(gulp.dest(paths.build + 'scripts/'));
});
gulp.task('build-scripts-external', function() {
  return bowerFiles()
    .pipe(filter('**/*.js'))
    .pipe(filter('!underscore/**/*')) // TODO: Remove this hack (backbone dep not needed)
    .pipe(filter('!jQuery/**/*')) // TODO: Remove this hack (iframe-resizer invalid dep - should be lowercase)
    .pipe(env == 'development' ? gutil.noop() : uglify())
    .pipe(concat('vendor.js'))
    .pipe(rev())
    .pipe(gulp.dest(paths.build + 'scripts/'));
});
gulp.task('build-scripts', ['build-scripts-internal', 'build-scripts-external']);


gulp.task('build-styles-internal', function() {
  return gulp.src(paths.styles)
    .pipe(compass({
      config_file: 'compass.rb',
      sass: 'app/styles/', // must be same as in compass config
      css: '.tmp/styles/' // must be same as in compass config
    }))
    .on('error', function(err) { logError(err); })
    .pipe(concat("app.css"))
    .pipe(rev())
    .pipe(gulp.dest(paths.build + 'styles/'))
});
gulp.task('build-styles-external', ['_getVendorPreScss'], function() {
  var scssFilter = filter('**/*.scss')
  return es.concat(
    bowerFiles().pipe(filter('**/*.{scss,css}')),
    gulp.src(paths.stylesVendor)
  )
    .pipe(scssFilter)
    .pipe(insert.prepend(vendorPreScss))
    .pipe(sass())
    .on('error', function(err) { logError(err); })
    .pipe(scssFilter.restore())
    .pipe(concat("vendor.css"))
    .pipe(rev())
    .pipe(gulp.dest(paths.build + 'styles/'))
});
gulp.task('build-styles', ['build-styles-internal', 'build-styles-external']);

gulp.task('build-templates', function() {
  // Precompile lodash templates into window.templates["relpath/filename.html", ...]
 return gulp.src(paths.templates)
    .pipe(template({
      namespace: 'templates'
    }))
    .on('error', function(err) { logError(err); })
    .pipe(concat("templates.js"))
    .pipe(rev())
    .pipe(gulp.dest(paths.build + 'scripts/'));
});

gulp.task('build-index', ['build-scripts', 'build-styles', 'build-templates'], function() {
  var apiHost = ((localConfig || {targets:{}}).targets[env] || {}).apiHost || '';
  return gulp.src([
      paths.build + '**/*vendor*.{css,js}',
      paths.build + '**/*templates*.js',
      paths.build + '**/*app*.{css,js}'
    ])
    .pipe(inject(paths.index, {
      addRootSlash: true,
      ignorePath: paths.build
    }))
    .pipe(preprocess({context: {ENV: env, API_HOST: apiHost}}))
    .pipe(gulp.dest(paths.build));
});

gulp.task('watch', function () {
  // Watch for changes in files and rebuild them to build/
  // TODO: watch project and external separately for faster changes
  gulp.watch(paths.scripts, ['build-scripts']);
  gulp.watch(paths.styles.concat(paths.stylesVendor, paths.stylesVendorPrepend), ['build-styles']);
  gulp.watch(paths.images, ['build-assets']);
  gulp.watch(paths.index, ['build-index']);
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
    gutil.log(cl.green('Server listening on port: ') + cl.magenta(port));
    next();
  });
});

gulp.task('clean', function() {
  gulp.src(paths.build, {read: false})
    .pipe(clean());
});

function notifyDeploy(duration) {

  function postNotification(head) {
    var postData = {
      token: localConfig.deployInfo.appToken,
      operator: process.env.USER,
      target: env,
      branch: head.branch,
      revision: head.revision,
      duration: duration
    };
    request.post({
      url: localConfig.deployInfo.url,
      method: 'POST',
      form: postData
    }, function(error, response) {
      if(error) {
        gutil.log(cl.red("Error: Failed to send deployment notification, error was:\n"), error);
      }
    });
  }

  function gitInfo(cb) {
    exec('echo "`git rev-parse HEAD` `git branch | sed -n \'/\* /s///p\'`"', function(error, stdout, stderr) {
      var output = stdout.trim().split(' ');
      var head = {
        branch: output && output[1] || 'unknown',
        revision: output && output[0] || 'unknown'
      }
      cb(head);
    });
  }

  gitInfo(postNotification);

};

gulp.task('deploy', ['build'], function() {

  if(!localConfig) { gutil.log(cl.red("Error: You need a local_config.json to be able to deploy")); return; }
  if(env == 'development') { gutil.log(cl.red("Error: Please specify a deployment target other than development using -e")); return; }
  if(!localConfig.targets[env]) { gutil.log(cl.red("Error: Please specify a deployment target that exists in local_config.json using -e")); return; }

  targetConfig = localConfig.targets[env];

  if(targetConfig.root[0] != '/') { gutil.log(cl.red("Error: Please specify the remote root as an absolute path")); return; }

  if(!targetConfig.root.match('\/$')) {
    targetConfig.root += '/';
  }

  var sshConfig = {
    host: targetConfig.host,
    port: targetConfig.port || 22
  }

  var deployStart = Date.now();

  gulp.src('')
    .pipe(shell([
      'ssh root@hubert "mkdir -p ' + targetConfig.root + '/current; cd ' + targetConfig.root + ';"',
      'rsync --checksum --archive --compress --delete --safe-links build/ ' + (targetConfig.user ? targetConfig.user + '@' : '') + targetConfig.host + ':' + targetConfig.root + 'current/'
    ]))
    .pipe(tap(function() {
      var time = Date.now() - deployStart;
      gutil.log(cl.green("Successfully deployed to ") + cl.yellow(env) + cl.green(" in ") + cl.yellow((time/1000).toFixed(2) + " seconds"));
      if(localConfig.deployInfo) notifyDeploy(time);
    }));

});

var bumpVersion = function(type) {

  type = type || 'patch';
  var version = '';

  gulp.src(['./bower.json', './package.json'])
    .pipe(bump({type: type}))
    .pipe(gulp.dest('./'))
    .pipe(tap(function(file, t) {
      version = JSON.parse(file.contents.toString()).version;
    })).on('end', function() {
      gulp.src('')
        .pipe(shell([
          'git commit --all --message "Version ' + version + '"',
          (type != 'patch' ? 'git tag --annotate "v' + version + '" --message "Version ' + version + '"' : 'true')
        ], {ignoreErrors: true}))
        .pipe(tap(function() {
          gutil.log(cl.green("Version bumped to ") + cl.yellow(version) + cl.green(", don't forget to push!"));
        }));
    });

}

gulp.task('bump', function() { bumpVersion('patch'); });
gulp.task('bump:patch', function() { bumpVersion('patch'); });
gulp.task('bump:minor', function() { bumpVersion('minor'); });
gulp.task('bump:major', function() { bumpVersion('major'); });

gulp.task('build', ['build-assets', 'build-scripts', 'build-styles', 'build-templates', 'build-index']);
gulp.task('default', ['build', 'watch', 'livereload', 'serve']);
