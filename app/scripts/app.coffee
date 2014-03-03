#
# Single point of entry for the whole application is PipesApp.initialize
# Initialize stuff there !
#

$(document).foundation()
$ -> window.pipes.initialize()

class PipesApp

  models: {}
  views: {}
  router: null

  apiUrl: (url) ->
    "/pipes#{url}"

  actions:
    index: ->

      $('#content').html templates['index.html']()

      if not pipes.integrationsListView
        pipes.integrationsListView = new pipes.views.IntegrationsListView
          el: $('.integrations-list')
          collection: new pipes.models.IntegrationCollection([
            new pipes.models.Integration(
              name: 'Basecamp'
              image: 'images/logo-basecamp.png'
              link: '#'
              pipes: new pipes.models.PipeCollection([
                new pipes.models.Pipe(
                  id: 'users'
                  name: 'Users'
                  description: 'Basecamp users will be imported to Toggl as users.'
                  status: {
                    type: 'success'
                    message: '5 users imported'
                  },
                  last_sync: {
                    date: 'Sep 1, 2013, 14:30'
                    log_url: '#'
                  }
                )
              ])
            )
          ])
      pipes.integrationsListView.render()

  initialize: ->

    if window.self == window.top
      $('body').addClass 'no-frame'

    @router = new pipes.AppRouter()
    Backbone.history.start()

window.pipes = new PipesApp()

class pipes.AppRouter extends Backbone.Router
  routes:
    '': 'index'

  index: pipes.actions.index
