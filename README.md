# Toggl Pipes UI

User Interface for the Toggl Pipes project. Currently in development.

## Contributing

Dependencies: 
 - [Ruby 2.6.3](https://www.ruby-lang.org/en/)
 - [Bundler 1.17.2](https://bundler.io/)
 - [NVM v0.35.3](https://github.com/nvm-sh/nvm)
 - [NodeJS 0.10.33](https://nodejs.org/en/)
 - [Compass 1.0.3](https://rubygems.org/gems/compass/versions/1.0.3)
 
After installing dependencies, you can install the required npm & bower packages:

## Prepare development environment

- Run `nvm install` inside the project directory. It setup needed `node` and `npm` versions.
- Install [Compass 1.0.3](https://rubygems.org/gems/compass/versions/1.0.3) with Bundler `bundle install`
- Run `npm install` (it also will run `bower install`)

### Gulp commands

ATTENTION: USE LOCALLY INSTALLED DEPENDENCIES FROM `./node_modules/.bin/gulp`

`./node_modules/.bin/gulp`
Runs the development server on port 7001 and watches for file changes.

`./node_modules/.bin/gulp build [-e target]`
Makes a clean build for the specified target (minifies, etc if target != development)

`./node_modules/.bin/gulp clean`
Removes build/ dir

`./node_modules/.bin/gulp bump[:patch]`
`./node_modules/.bin/gulp bump:minor`
`./node_modules/.bin/gulp bump:major`
Bump the project version number. Bumps patch version by default. Also creates a tag if type is minor or major.
NB! Bumping creates a commit, you need to `git push` it manually!

`./node_modules/.bin/gulp deploy -e <target> [-b major|minor|patch]`
Builds & deploys the app to the target server via ssh & rsync. The project root can be configured in `local_config` and the app is deployed under <project-root>/current and the previous version is backed up to <project-root>/previous.
Optionally bumps the version before deployment if the -b option is present.

### local_config

You need a `local_config` package to be able to talk to the API and/or deploy. (Togglers: see readme in pipes-ui-conf in gitosis)
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
