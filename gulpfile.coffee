gulp = require("gulp")
fs = require("fs")
es = require("event-stream")
path = require("path")
insert = require("gulp-insert")
sass = require("gulp-sass")
compass = require("gulp-compass")
minifyCSS = require("gulp-minify-css")
coffee = require("gulp-coffee")
concat = require("gulp-concat")
uglify = require("gulp-uglify")
template = require("gulp-template-compile")
minifyHTML = require("gulp-minify-html")
preprocess = require("gulp-preprocess")
bowerFiles = require("gulp-bower-files")
flatten = require("gulp-flatten")
watch = require("gulp-watch")
livereload = require("gulp-livereload")
print = require("gulp-print")
filter = require("gulp-filter")
gutil = require("gulp-util")
notifier = require("node-notifier")
Entities = require("html-entities").XmlEntities
shell = require("gulp-shell")
bump = require("gulp-bump")
tap = require("gulp-tap")
rev = require("gulp-rev")
inject = require("gulp-inject")
request = require("request")
imagemin = require("gulp-imagemin")
exec = require("child_process").exec
htmlEntities = new Entities()

cl = gutil.colors

# Custom notification function because gulp-notify doesn't work for some reason
logError = (error, print) ->
  gutil.log error  if print
  msg = htmlEntities.encode(gutil.colors.stripColor(error.message).replace(/[\r\n ]+/g, " "))
  notifier.notify
    title: "Pipes build error"
    message: msg


# =====
# Setup
# =====

env = gutil.env.e or "development"

paths =
  scripts: [ # in specific order => app.js
    "app/scripts/app.coffee"
    "app/scripts/views/list-view.coffee"
    "app/scripts/views/steps/step.coffee"
    "app/scripts/views/steps/datapoll-step.coffee"
    "app/scripts/**/*.coffee"
    "!app/scripts/vendor/**/*.coffee"
  ]
  styles: [ # => app.css
    "app/styles/**/*.scss"
    "!app/styles/vendor/**/*.scss"
  ]
  stylesVendorPrepend: "app/styles/_globals.scss" # special hack to allow configuring of external foundation, prepended to => vendor.css
  stylesVendor: ["app/styles/vendor/**/*.scss"] # => appended to vendor.css after css from bower packages
  templates: ["app/templates/**/*.html"] # window.templates[filepath] = <compiled template>, => templates.js
  index: "app/index.html"
  images: "app/images/**/*"
  build: "build/"


localConfig = null
try
  localConfig = require("./local_config")
catch err
  localConfig = null
  gutil.log cl.yellow("Warning: You need a local_config.json to be able to deploy or specify api host")

vendorPreScss = "" # String to prepend to all vendor scss files

gulp.task "_getVendorPreScss", (cb) -> # Registering this as task to be able to specify as task dep
  fs.readFile paths.stylesVendorPrepend, "utf8", (err, data) ->
    return  if err
    vendorPreScss = data
    cb()


# =====
# Tasks
# =====


gulp.task "build-assets-internal", ->
  gulp.src(paths.images)
    .pipe imagemin()
    .pipe gulp.dest(paths.build + "images/")

gulp.task "build-assets-external", ->
  bowerFiles()
    .pipe filter("**/*.{otf,eot,svg,ttf,woff}")
    .pipe flatten()
    .pipe gulp.dest(paths.build + "fonts/")

gulp.task "build-assets", ["build-assets-internal", "build-assets-external"]


gulp.task "build-scripts-internal", ->
  gulp.src(paths.scripts)
    .pipe coffee()
    .on "error", (err) -> logError(err, true)
    .pipe (if env is "development" then gutil.noop() else uglify())
    .pipe concat("app.js")
    .pipe (if env is "development" then gutil.noop() else rev())
    .pipe gulp.dest(paths.build + "scripts/")

gulp.task "build-scripts-external", ->
  bowerFiles()
    .pipe filter("**/*.js")
    .pipe filter("!underscore/**/*") # TODO: Remove this hack (backbone dep not needed)
    .pipe filter("!jQuery/**/*") # TODO: Remove this hack (iframe-resizer invalid dep - should be lowercase)
    .pipe (if env is "development" then gutil.noop() else uglify())
    .pipe concat("vendor.js")
    .pipe (if env is "development" then gutil.noop() else rev())
    .pipe gulp.dest(paths.build + "scripts/")

gulp.task "build-scripts", ["build-scripts-internal", "build-scripts-external"]


gulp.task "build-styles-internal", ->
  gulp.src(paths.styles)
    .pipe compass(
      project: "."
      sass: "app/styles/"
      css: ".tmp/styles/"
      style: (if env is "development" then "expanded" else "compressed")
    )
    .on "error", (err) -> logError(err)
    .pipe (if env is "development" then gutil.noop() else minifyCSS())
    .pipe concat("app.css")
    .pipe (if env is "development" then gutil.noop() else rev())
    .pipe gulp.dest(paths.build + "styles/")

gulp.task "build-styles-external", ["_getVendorPreScss"], ->
  scssFilter = filter("**/*.scss")
  es.concat(
    bowerFiles().pipe(filter("**/*.{scss,css}")),
    gulp.src(paths.stylesVendor)
  )
    .pipe scssFilter
    .pipe insert.prepend(vendorPreScss)
    .pipe sass()
    .on "error", (err) -> logError(err)
    .pipe scssFilter.restore()
    .pipe (if env is "development" then gutil.noop() else minifyCSS())
    .pipe concat("vendor.css")
    .pipe (if env is "development" then gutil.noop() else rev())
    .pipe gulp.dest(paths.build + "styles/")

gulp.task "build-styles", ["build-styles-internal", "build-styles-external"]


gulp.task "build-templates", ->
  # Precompile lodash templates into window.templates["relpath/filename.html", ...]
  gulp.src(paths.templates)
    .pipe template(namespace: "templates")
    .on "error", (err) -> logError(err)
    .pipe concat("templates.js")
    .pipe (if env is "development" then gutil.noop() else uglify())
    .pipe (if env is "development" then gutil.noop() else rev())
    .pipe gulp.dest(paths.build + "scripts/")


gulp.task "build-index", ["build-scripts", "build-styles", "build-templates"], ->
  targetConfig = localConfig?.targets?[env] or {}
  apiHost = targetConfig.apiHost or ""
  gaCode = targetConfig.googleAnalytics?.trackingCode or ""
  gaDomain = targetConfig.googleAnalytics?.domain or ""
  gulp.src([
    "#{paths.build}**/*vendor*.{css,js}"
    "#{paths.build}**/*templates*.js"
    "#{paths.build}**/*app*.{css,js}"
  ])
    .pipe inject(paths.index,
      addRootSlash: true
      ignorePath: paths.build
    )
    .pipe preprocess(context:
      ENV: env
      API_HOST: apiHost
      GA_CODE: gaCode
      GA_DOMAIN: gaDomain
    )
    .pipe (if env is "development" then gutil.noop() else minifyHTML())
    .pipe gulp.dest(paths.build)

gulp.task "watch", ["build"], ->
  # Watch for changes in files and rebuild them to build/
  # TODO: watch project and external separately for faster changes
  gulp.watch paths.scripts, ["build-scripts"]
  gulp.watch paths.styles.concat(paths.stylesVendor, paths.stylesVendorPrepend), ["build-styles"]
  gulp.watch paths.images, ["build-assets"]
  gulp.watch paths.index, ["build-index"]
  gulp.watch paths.templates, ["build-templates"]

gulp.task "livereload", ->
  # Trigger browser refresh when smth changes in build/
  server = livereload(35710)
  gulp.watch(paths.scripts).on "change", (file) ->
    setTimeout (->server.changed file.path), 1500

  gulp.watch(paths.styles).on "change", (file) ->
    setTimeout (->server.changed file.path), 2000

  gulp.watch(paths.stylesVendor).on "change", (file) ->
    setTimeout (->server.changed file.path), 2000

  gulp.watch(paths.stylesVendorPrepend).on "change", (file) ->
    setTimeout (->server.changed file.path), 2000

  gulp.watch(paths.images).on "change", (file) ->
    setTimeout (->server.changed file.path), 2000

  gulp.watch(paths.index).on "change", (file) ->
    setTimeout (->server.changed file.path), 1500

  gulp.watch(paths.templates).on "change", (file) ->
    setTimeout (->server.changed file.path), 1500

gulp.task "serve", (next) ->
  # Serve files in build/ for local testing
  staticS = require("node-static")
  server = new staticS.Server(paths.build)
  port = 7001
  require("http").createServer (request, response) ->
    request.addListener "end", ->
      server.serve request, response
    request.resume()
  .listen port, ->
    gutil.log cl.green("Server listening on port: ") + cl.magenta(port)
    next()

gulp.task "clean", (cb) ->
  exec "rm -rf " + paths.build, -> cb()

notifyDeploy = (duration) ->

  postNotification = (head) ->
    postData =
      token: localConfig.deployInfo.appToken
      operator: process.env.USER
      target: env
      branch: head.branch
      revision: head.revision
      duration: duration

    request.post
      url: localConfig.deployInfo.url
      method: "POST"
      form: postData
    , (error, response) ->
      gutil.log cl.red("Error: Failed to send deployment notification, error was:\n"), error if error

  gitInfo = (cb) ->
    exec "echo \"`git rev-parse HEAD` `git branch | sed -n '/* /s///p'`\"", (error, stdout, stderr) ->
      output = stdout.trim().split(" ")
      head =
        branch: output and output[1] or "unknown"
        revision: output and output[0] or "unknown"
      cb head

  gitInfo(postNotification)

gulp.task "deploy", ["build"], ->

  if not localConfig
    gutil.log cl.red("Error: You need a local_config.json to be able to deploy")
    return

  if env is "development"
    gutil.log cl.red("Error: Please specify a deployment target other than development using -e")
    return

  if not localConfig.targets[env]
    gutil.log cl.red("Error: Please specify a deployment target that exists in local_config.json using -e")
    return

  targetConfig = localConfig.targets[env]

  if not targetConfig.root[0] is "/"
    gutil.log cl.red("Error: Please specify the remote root as an absolute path")
    return

  targetConfig.root += "/"  unless targetConfig.root.match("/$")

  sshConfig =
    host: targetConfig.host
    port: targetConfig.port or 22

  bumpVersion(gutil.env.b) if gutil.env.b

  deployStart = Date.now()

  gulp.src("")
    .pipe shell([
      "ssh " + targetConfig.host + " \"cd " + targetConfig.root + "; mkdir -p current; rm -rf previous; cp -r current previous\""
      "rsync --checksum --archive --compress --delete --safe-links build/ " + ((if targetConfig.user then targetConfig.user + "@" else "")) + targetConfig.host + ":" + targetConfig.root + "current/"
    ])
    .pipe tap ->
      time = Date.now() - deployStart
      gutil.log cl.green("Successfully deployed to ") + cl.yellow(env) + cl.green(" in ") + cl.yellow((time / 1000).toFixed(2) + " seconds")
      notifyDeploy(time) if localConfig.deployInfo

bumpVersion = (type) ->
  type = type or "patch"
  version = ""
  gulp.src [
    "./bower.json"
    "./package.json"
  ]
  .pipe bump(type: type)
  .pipe gulp.dest("./")
  .pipe tap (file, t) -> version = JSON.parse(file.contents.toString()).version
  .on "end", ->
    gulp.src("")
      .pipe shell([
        "git commit --all --message \"Version " + version + "\""
        (if type isnt "patch" then "git tag --annotate \"v" + version + "\" --message \"Version " + version + "\"" else "true")
      ], ignoreErrors: true)
      .pipe tap ->
        gutil.log cl.green("Version bumped to ") + cl.yellow(version) + cl.green(", don't forget to push!")

gulp.task "bump", -> bumpVersion("patch")

gulp.task "bump:patch", -> bumpVersion("patch")

gulp.task "bump:minor", -> bumpVersion("minor")

gulp.task "bump:major", -> bumpVersion("major")

gulp.task "build", [
  "clean"
  "build-assets"
  "build-scripts"
  "build-styles"
  "build-templates"
  "build-index"
]
gulp.task "default", [
  "build"
  "watch"
  "livereload"
  "serve"
]