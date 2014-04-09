# Toggl Pipes UI

User Interface for the Toggl Pipes project. Currently in development.

## Contributing

Dependencies: NodeJS, CoffeScript, Compass, Bower.
After installing dependencies, you can install the required npm & bower packages:

Install Gulp
`npm install -g gulp`.

Then, to install all the dependencies run `npm install` and `bower install`.

### Gulp commands

`gulp`
Runs the development server on port 7001 and watches for file changes.

`gulp build [-e target]`
Makes a clean build for the specified target (minifies, etc if target != development)

`gulp clean`
Removes build/ dir

`gulp bump[:patch]`
`gulp bump:minor`
`gulp bump:major`
Bump the project version number. Bumps patch version by default. Also creates a tag if type is minor or major.
NB! Bumping creates a commit, you need to `git push` it manually!

`gulp deploy -e <target> [-b major|minor|patch]`
Builds & deployes the app to the target server via ssh & rsync. The project root can be configured in local_config.json and the app is deployed under <project-root>/current and the previous version is backed up to <project-root>/previous.
Optionally bumps the version before deployment if the -b option is present.

### local_config.json

You need a `local_config.json` file to be able to talk to the API and/or deploy.
Sample `local_config.json`

```json
{
  "targets": {
    "development": {
      "apiHost": "https://my-dev-pipes-api-host.com"
    },
    "production": {
      "host": "my-production-server-host",
      "root": "/project/root/folder/",
      "apiHost": "https://my-production-pipes-api-host.com"
    }
  }
}
```