# Toggl Pipes UI

User Interface for the Toggl Pipes project. Currently in development.

## Contributing

To run, install NodeJS and gulp via `npm install -g gulp`. Then to install all the dependencies run `npm install` and `bower install`.

### local_config.json

You need a `local_config.json` file to be able to talk to the API and/or deploy.
Sample `local_config.json`

```json
{
  "targets": {
    "development": {
      "apiHost": "https://my-dev-pipes-api-host.com"
    },
    "staging": {
      "host": "my-production-server-host",
      "root": "/project/root/folder/",
      "apiHost": "https://my-production-pipes-api-host.com"
    }
  }
}
```