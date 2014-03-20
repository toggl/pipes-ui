# Toggl Pipes UI

User Interface for the Toggl Pipes project. Currently in development.

## Contributing

To run, first install NodeJS and gulp via `npm install -g gulp`.
Then, to install all the dependencies run `npm install` and `bower install`.

To run the development server and watch for file changes, simply run `gulp`.

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