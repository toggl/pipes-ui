# Toggl Pipes UI

User Interface for the Toggl Pipes project. It's DEPRECATED now, but still used in production.
It uses [pipes-api](https://github.com/toggl/pipes-api) as a Backend.

It has written with [CoffeeScript 1.7](https://coffeescript.org/).
It uses [jQuery (ajax)](https://api.jquery.com/jquery.ajax/) to communicate with backend.
It also uses [Compass 1.0.3](https://rubygems.org/gems/compass/versions/1.0.3) SASS/CSS framework and [Foundation 5](https://get.foundation/sites/docs-v5/) as a UI framework.
UI components has built with [lodash templates](https://lodash.com/docs#template) and [backbone.js](https://backbonejs.org/).

## Contributing

Dependencies:

 - [Ruby](https://www.ruby-lang.org/en/)
    - [Bundler](https://bundler.io/)
 - [NVM](https://github.com/nvm-sh/nvm)
    - [NodeJS](https://nodejs.org/en/)
 
After installing dependencies, you can install the required `npm` & `bower` packages:

## Prepare development environment

- Install Ruby and Bundler.
- Run `bundle install`. It will install `Compass`.
- Run `nvm install`. It will install needed `node` and `npm` versions.
- Run `npm install` (it also will run `bower install` automatically).

After steps above you can use locally installed `./node_modules/.bin/gulp ` for building and running the project.

### Gulp commands

- `./node_modules/.bin/gulp build [-e target]` Makes a clean build for the specified target (minifies, etc if target != development)
- `./node_modules/.bin/gulp clean` Removes build/ dir

```bash
./node_modules/.bin/gulp bump[:patch]
./node_modules/.bin/gulp bump:minor
./node_modules/.bin/gulp bump:major
```

Bump the project version number. Bumps patch version by default. Also creates a tag if type is minor or major.
NB! Bumping creates a commit, you need to `git push` it manually!

```bash
./node_modules/.bin/gulp deploy -e <target> [-b major|minor|patch]
```

Builds & deploys the app to the target server via ssh & rsync. The project root can be configured in `local_config` and the app is deployed under <project-root>/current and the previous version is backed up to <project-root>/previous.
Optionally bumps the version before deployment if the -b option is present.

### local_config

You need a `local_config` package to be able to talk to the API and/or deploy. (Togglers: see README.md in [pipes-ui-conf](https://github.com/toggl/pipes-ui-conf))
Sample `local_config/index.json`

```json
{
  "targets": {
    "development": {
      "apiHost": "https://my-dev-pipes-api-host.com"
    },
    "production": {
      "host": "my-production-server-host",
      "root": "/project/root/folder/",
      "apiHost": "https://my-production-pipes-api-host.com",
      "googleAnalytics": {
        "trackingCode": "UA-1111111-22",
        "domain": "example.com"
      }
    }
  }
}
```
