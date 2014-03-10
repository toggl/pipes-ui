#
# Single point of entry for the whole application is PipesApp.initialize
# Initialize stuff there !
#

$(document).foundation()
$ -> window.pipes.initialize()

# Global custom checkboxes (structure: input.custom.checkbox + span.checkbox)

$(document.body).on 'click', 'span.checkbox', (e) ->
  $input = $(e.currentTarget).siblings('input:checkbox.custom.checkbox')
  $input.prop 'checked', not $input.prop('checked')
  $input.change()
$(document.body).on 'change', 'input:checkbox.custom.checkbox', (e) ->
  $(e.currentTarget).siblings('span.checkbox').toggleClass 'checked', $(e.currentTarget).is(':checked')
$(document.body).on 'click', '.button.checkbox:not(.dropdown)', (e) ->
  if e.currentTarget == e.target
    $(e.currentTarget).children('span.checkbox').click()

class PipesApp

  models: {}
  views: {}
  steps: {}
  router: null

  apiUrl: (url) ->
    "/pipes#{url}"

  windowApi: null

  actions:
    index: ->

      $('#content').html templates['index.html']()

      if not pipes.integrationsListView
        pipes.integrationsListView = new pipes.views.IntegrationsListView
          el: $('.integrations-list')
          collection: new pipes.models.IntegrationCollection([
            new pipes.models.Integration(
              id: 'basecamp'
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
      pipes.integrationsListView.collection.models[0].get('pipes').integration = pipes.integrationsListView.collection.models[0]
      pipes.integrationsListView.render()

  initialize: ->

    if window.self == window.top
      $('body').addClass 'no-frame'

    @router = new pipes.AppRouter()
    Backbone.history.start()

    @windowApi = new pipes.WindowApi()
    @windowApi.initialize()
    @windowApi.on 'documentUrl', (documentUrl) ->
      console.log('WOOOHOOO', 'documentUrl:', documentUrl)

window.pipes = new PipesApp()

class pipes.AppRouter extends Backbone.Router
  routes:
    '': 'index'

  index: pipes.actions.index
